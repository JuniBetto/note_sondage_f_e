// Run explicitly with flutter test. No _test.dart suffix: excluded from the
// normal suite. Kept under test/ so the Chrome runner can serve the source.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_message_entity.dart';
import 'package:note_sondage/feature/chat/infrastructure/data_source/chat_local_data_source.dart';
import 'package:note_sondage/feature/chat/infrastructure/data_source/chat_remote_data_source.dart';
import 'package:note_sondage/feature/chat/infrastructure/repositories/chat_repository_impl.dart';

import 'chat_cache_fixtures.dart';

const _samples = 20;
const _warmups = 3;
const _cacheFormat = String.fromEnvironment(
  'CHAT_CACHE_FORMAT',
  defaultValue: 'legacy',
);

Map<String, num> _stats(List<int> values) {
  final sorted = [...values]..sort();
  final middle = sorted.length ~/ 2;
  return {
    'median_ms': sorted.length.isEven
        ? (sorted[middle - 1] + sorted[middle]) / 2000
        : sorted[middle] / 1000,
    'p95_ms': sorted[(sorted.length * .95).ceil() - 1] / 1000,
    'min_ms': sorted.first / 1000,
    'max_ms': sorted.last / 1000,
  };
}

class _ConfirmedRemote extends ChatRemoteDataSource {
  _ConfirmedRemote(this.message);
  final ChatMessageEntity message;

  @override
  Future<ChatMessageEntity> sendMessage(
    String conversationId,
    String content, {
    String? replyToMessageId,
  }) async => message;
}

void main() {
  setUpAll(initializeCacheTestAuth);

  test(
    '$_cacheFormat cache: box open, first read, warm read and upsert',
    () async {
      expect(_cacheFormat, anyOf('legacy', 'migrated'));
      final rows = <Map<String, Object?>>[];
      // Rotate the order per repetition to reduce systematic warmup/GC bias.
      final counts = [1, 10, 100, 500];
      final measurements = <int, Map<String, List<int>>>{
        for (final count in counts)
          count: {
            'box_open': [],
            'first_chat_read': [],
            'warm_chat_read': [],
            'upsert': [],
            'repository_return': [],
            'repository_durable': [],
            if (_cacheFormat == 'migrated') 'migration': [],
          },
      };
      final sizes = <int, int>{};
      for (var sample = -_warmups; sample < _samples; sample++) {
        final order = [...counts]..shuffle(Random(sample + _warmups));
        for (final count in order) {
          final directory = kIsWeb
              ? null
              : await Directory.systemTemp.createTemp('chat-cache-benchmark-');
          try {
            if (directory != null) Hive.init(directory.path);
            var box = await Hive.openBox<String>(chatCacheBoxName);
            sizes[count] = await seedLegacyChatCache(box, conversations: count);
            if (_cacheFormat == 'migrated') {
              final migrationTimer = Stopwatch()..start();
              await ChatLocalDataSource().migrateLegacyMessages();
              migrationTimer.stop();
              if (sample >= 0) {
                measurements[count]!['migration']!.add(
                  migrationTimer.elapsedMicroseconds,
                );
              }
              // Include the actual migrated payload sizes and measure the
              // first restart after the real migration (including its compaction).
              sizes[count] = box.values.fold<int>(
                0,
                (size, raw) => size + utf8.encode(raw).length,
              );
              expect(box.containsKey('messages::$cacheUserId'), isFalse);
            }
            await Hive.close();
            final timer = Stopwatch()..start();
            box = await Hive.openBox<String>(chatCacheBoxName);
            timer.stop();
            final openUs = timer.elapsedMicroseconds;
            final local = ChatLocalDataSource();
            timer
              ..reset()
              ..start();
            final conversation = local.getConversationByTeamId('team-0');
            final first = local.getMessages(conversation!.id);
            timer.stop();
            final firstUs = timer.elapsedMicroseconds;
            expect(first, hasLength(50));
            timer
              ..reset()
              ..start();
            final warm = local.getMessages(conversation.id);
            timer.stop();
            final warmUs = timer.elapsedMicroseconds;
            expect(warm.last.id, 'conversation-0-message-49');
            timer
              ..reset()
              ..start();
            await local.upsertMessage(conversation.id, cacheMessage(index: 50));
            timer.stop();
            final upsertUs = timer.elapsedMicroseconds;
            final confirmed = cacheMessage(index: 51);
            final repository = ChatRepositoryImpl(
              local,
              _ConfirmedRemote(confirmed),
            );
            timer
              ..reset()
              ..start();
            final sent = await repository.sendMessage(
              conversation.id,
              confirmed.contentText,
            );
            final returnUs = timer.elapsedMicroseconds;
            await local.flushPendingWrites();
            timer.stop();
            final durableUs = timer.elapsedMicroseconds;
            expect(sent.id, confirmed.id);
            expect(
              ChatLocalDataSource().getMessages(conversation.id).last.id,
              confirmed.id,
            );
            if (sample >= 0) {
              final metrics = measurements[count]!;
              metrics['box_open']!.add(openUs);
              metrics['first_chat_read']!.add(firstUs);
              metrics['warm_chat_read']!.add(warmUs);
              metrics['upsert']!.add(upsertUs);
              metrics['repository_return']!.add(returnUs);
              metrics['repository_durable']!.add(durableUs);
            }
          } finally {
            await Hive.close();
            if (kIsWeb) {
              await Hive.deleteBoxFromDisk(chatCacheBoxName);
            } else {
              await directory!.delete(recursive: true);
            }
          }
        }
      }
      for (final count in counts) {
        rows.add({
          'conversations': count,
          'messages_per_conversation': 50,
          'seed_json_bytes': sizes[count],
          for (final metric in measurements[count]!.entries)
            metric.key: {..._stats(metric.value), 'samples_us': metric.value},
        });
      }
      final report = {
        'schema_version': 3,
        'cache_format': _cacheFormat,
        'measured_at_utc': DateTime.now().toUtc().toIso8601String(),
        'runtime': kIsWeb
            ? 'Flutter Chrome test runner (JavaScript)'
            : Platform.version,
        'os': kIsWeb
            ? 'browser (host details in STEP4.md)'
            : Platform.operatingSystemVersion,
        'samples': _samples,
        'warmups': _warmups,
        'mode':
            'flutter_test ${kIsWeb ? 'Chrome IndexedDB' : 'host VM'}; synthetic $_cacheFormat cache; no UI or network',
        'results': rows,
      };
      const outputPath = String.fromEnvironment('CHAT_CACHE_BENCHMARK_OUTPUT');
      if (!kIsWeb && outputPath.isNotEmpty) {
        final file = File(outputPath);
        await file.parent.create(recursive: true);
        await file.writeAsString(
          const JsonEncoder.withIndent('  ').convert(report),
        );
      }
      // Machine-readable output also available without an output path.
      // ignore: avoid_print
      print('CHAT_CACHE_BENCHMARK ${jsonEncode(report)}');
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
