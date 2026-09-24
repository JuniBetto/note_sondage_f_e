import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_conversation_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_direct_conversation_summary_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_message_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_message_reaction_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_message_reply_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_team_conversation_summary_entity.dart';
import 'package:note_sondage/feature/chat/infrastructure/data_source/chat_local_data_source.dart';
import 'package:note_sondage/feature/chat/infrastructure/data_source/chat_remote_data_source.dart';
import 'package:note_sondage/feature/chat/infrastructure/repositories/chat_repository_impl.dart';

import '../../../../support/chat_cache_fixtures.dart';

class _RemotePage extends ChatRemoteDataSource {
  List<ChatMessageEntity> page = [];
  Future<void>? responseGate;

  @override
  Future<ChatMessageEntity> sendMessage(
    String conversationId,
    String content, {
    String? replyToMessageId,
  }) async {
    await responseGate;
    return cacheMessage(conversationId: conversationId, content: content);
  }

  @override
  Future<List<ChatMessageEntity>> getMessages(
    String conversationId, {
    DateTime? before,
    int limit = 50,
  }) async {
    await responseGate;
    return page;
  }
}

class _BurstRemote extends _RemotePage {
  int sent = 0;

  @override
  Future<ChatMessageEntity> sendMessage(
    String conversationId,
    String content, {
    String? replyToMessageId,
  }) async => cacheMessage(
    index: sent++,
    conversationId: conversationId,
    content: content,
  );
}

String _key(String conversationId, [String scope = cacheUserId]) =>
    'messages_v2::${Uri.encodeComponent(scope)}::${Uri.encodeComponent(conversationId)}';

class _ObservedBox extends Fake implements Box<String> {
  _ObservedBox(this.delegate);
  final Box<String> delegate;
  final reads = <dynamic>[];
  final writes = <dynamic>[];
  bool failCopy = false;
  bool failFlush = false;
  bool failDelete = false;
  bool failPut = false;
  bool failCompact = false;
  int compactions = 0;
  Completer<void>? copyGate;
  Completer<void>? putGate;
  final putStarted = Completer<void>();
  final copyStarted = Completer<void>();

  @override
  String? get(dynamic key, {String? defaultValue}) {
    reads.add(key);
    return delegate.get(key, defaultValue: defaultValue);
  }

  @override
  bool containsKey(dynamic key) => delegate.containsKey(key);

  @override
  Future<void> put(dynamic key, String value) async {
    if (!putStarted.isCompleted) putStarted.complete();
    if (putGate != null) await putGate!.future;
    if (failPut) throw StateError('write failed');
    writes.add(key);
    return delegate.put(key, value);
  }

  @override
  Future<void> putAll(Map<dynamic, String> entries) async {
    if (!copyStarted.isCompleted) copyStarted.complete();
    if (copyGate != null) await copyGate!.future;
    if (failCopy) throw StateError('copy failed');
    writes.addAll(entries.keys);
    await delegate.putAll(entries);
  }

  @override
  Future<void> flush() {
    if (failFlush) throw StateError('flush failed');
    return delegate.flush();
  }

  @override
  Future<void> compact() {
    compactions++;
    if (failCompact) throw StateError('compaction failed');
    return delegate.compact();
  }

  @override
  Future<void> delete(dynamic key) {
    if (failDelete) throw StateError('delete failed');
    return delegate.delete(key);
  }
}

class _ObservedHive extends Fake implements HiveInterface {
  _ObservedHive(this.observedBox);
  final _ObservedBox observedBox;

  @override
  bool isBoxOpen(String name) => Hive.isBoxOpen(name);

  @override
  Box<E> box<E>(String name) => observedBox as Box<E>;
}

void main() {
  late CacheTestAuth auth;
  Directory? directory;
  late Box<String> box;
  late ChatLocalDataSource local;

  setUpAll(() async {
    auth = await initializeCacheTestAuth();
  });
  setUp(() async {
    auth.signInAs(cacheUserId);
    // Chrome's test runner uses an isolated origin/profile. Exercise its real
    // IndexedDB backend; native runs keep using a fresh filesystem directory.
    if (!kIsWeb) {
      directory = await Directory.systemTemp.createTemp('chat-cache-test-');
      Hive.init(directory!.path);
    }
    box = await Hive.openBox<String>(chatCacheBoxName);
    local = ChatLocalDataSource();
  });
  tearDown(() async {
    // Drain automatic migration, including intentionally failing test cases.
    await local.migrateLegacyMessages().catchError((Object _) {});
    await Hive.close();
    if (kIsWeb) {
      await Hive.deleteBoxFromDisk(chatCacheBoxName);
    } else {
      await directory!.delete(recursive: true);
    }
  });

  Future<ChatLocalDataSource> restart() async {
    await local.migrateLegacyMessages();
    await Hive.close();
    box = await Hive.openBox<String>(chatCacheBoxName);
    return ChatLocalDataSource();
  }

  test(
    '80 rapid server-confirmed sends remain ordered and durable after restart',
    () async {
      await local.saveMessages('conversation-1', [
        cacheMessage(conversationId: 'conversation-1'),
      ]);
      final untouched = box.get(_key('conversation-1'));
      final observed = _ObservedBox(box)..putGate = Completer<void>();
      local = ChatLocalDataSource(hive: _ObservedHive(observed));
      addTearDown(() {
        if (!observed.putGate!.isCompleted) observed.putGate!.complete();
      });
      final repository = ChatRepositoryImpl(local, _BurstRemote());
      final confirmed = await Future.wait([
        for (var index = 0; index < 80; index++)
          repository.sendMessage('conversation-0', 'Burst $index'),
      ]);
      await observed.putStarted.future;
      expect(confirmed, hasLength(80));
      expect(
        local.getMessages('conversation-0').map((item) => item.id),
        confirmed.map((item) => item.id),
      );
      expect(box.get(_key('conversation-0')), isNull);

      observed.putGate!.complete();
      await local.flushPendingWrites();
      expect(box.get(_key('conversation-1')), untouched);
      local = await restart();
      final restored = local.getMessages('conversation-0');
      expect(
        restored.map((item) => item.id),
        confirmed.skip(30).map((item) => item.id),
      );
      expect(restored.map((item) => item.id).toSet(), hasLength(50));
      expect(restored.last.contentText, 'Burst 79');
    },
  );

  test(
    'metadata reads do not read messages; each chat is loaded only on demand',
    () async {
      await seedLegacyChatCache(box, conversations: 3);
      await local.migrateLegacyMessages();
      final observed = _ObservedBox(box);
      local = ChatLocalDataSource(hive: _ObservedHive(observed));
      local.getConversationByTeamId('team-0');
      local.getTeamSummary('team-0');
      expect(
        observed.reads.where((key) => key.toString().startsWith('messages')),
        isEmpty,
      );
      observed.reads.clear();
      expect(local.getMessages('conversation-0'), hasLength(50));
      expect(observed.reads, [_key('conversation-0')]);
      observed.reads.clear();
      local.getMessages('conversation-0');
      expect(observed.reads, isEmpty);
      local.getMessages('conversation-2');
      expect(observed.reads, [_key('conversation-2')]);
    },
  );

  test(
    'saving a chat writes only its entry and keeps other chats unchanged',
    () async {
      await seedLegacyChatCache(box, conversations: 3);
      await local.migrateLegacyMessages();
      final untouched = box.get(_key('conversation-1'));
      final observed = _ObservedBox(box);
      local = ChatLocalDataSource(hive: _ObservedHive(observed));
      await local.upsertMessage('conversation-0', cacheMessage(index: 50));
      expect(observed.writes, [_key('conversation-0')]);
      expect(box.get(_key('conversation-1')), untouched);
      expect(box.containsKey('messages::$cacheUserId'), isFalse);
      expect(
        (jsonDecode(box.get(_key('conversation-0'))!) as List),
        hasLength(50),
      );
      expect(local.getMessages('conversation-0'), hasLength(51));
    },
  );

  test(
    'read-triggered migration copies unopened chats before removing legacy data',
    () async {
      await seedLegacyChatCache(box, conversations: 3);
      final observed = _ObservedBox(box)..copyGate = Completer<void>();
      local = ChatLocalDataSource(hive: _ObservedHive(observed));
      addTearDown(() {
        if (!observed.copyGate!.isCompleted) observed.copyGate!.complete();
      });
      expect(local.getMessages('conversation-0'), hasLength(50));
      await observed.copyStarted.future;
      expect(box.containsKey('messages::$cacheUserId'), isTrue);
      expect(box.containsKey(_key('conversation-2')), isFalse);
      observed.copyGate!.complete();
      await local.migrateLegacyMessages();
      expect(box.containsKey('messages::$cacheUserId'), isFalse);
      expect(box.containsKey(_key('conversation-2')), isTrue);
      local = await restart();
      expect(
        local.getMessages('conversation-2').last.id,
        'conversation-2-message-49',
      );
    },
  );

  test(
    'partial migration preserves new entries including empty authoritative pages',
    () async {
      await seedLegacyChatCache(box, conversations: 3);
      await box.put(_key('conversation-0'), '[]');
      final newer = jsonDecode(box.get('messages::$cacheUserId')!) as Map;
      (newer['conversation-1'] as List).last['contentText'] = 'Newer';
      await box.put(
        _key('conversation-1'),
        jsonEncode(newer['conversation-1']),
      );
      await local.migrateLegacyMessages();
      expect(local.getMessages('conversation-0'), isEmpty);
      expect(local.getMessages('conversation-1').last.contentText, 'Newer');
      expect(local.getMessages('conversation-2'), hasLength(50));
      expect(box.containsKey('messages::$cacheUserId'), isFalse);
    },
  );

  for (final failure in ['copy', 'flush', 'delete']) {
    test(
      'migration retains legacy after $failure failure and resumes on restart',
      () async {
        await seedLegacyChatCache(box, conversations: 2);
        final legacy = box.get('messages::$cacheUserId');
        final observed = _ObservedBox(box)
          ..failCopy = failure == 'copy'
          ..failFlush = failure == 'flush'
          ..failDelete = failure == 'delete';
        local = ChatLocalDataSource(hive: _ObservedHive(observed));
        await expectLater(local.migrateLegacyMessages(), throwsStateError);
        expect(box.get('messages::$cacheUserId'), legacy);
        await Hive.close();
        box = await Hive.openBox<String>(chatCacheBoxName);
        local = ChatLocalDataSource();
        await local.migrateLegacyMessages();
        expect(box.containsKey('messages::$cacheUserId'), isFalse);
        expect(local.getMessages('conversation-0'), hasLength(50));
        expect(local.getMessages('conversation-1'), hasLength(50));
      },
    );
  }

  test(
    'migration and queued writes preserve the latest update across account switches',
    () async {
      await seedLegacyChatCache(box, conversations: 2);
      final observed = _ObservedBox(box)..copyGate = Completer<void>();
      local = ChatLocalDataSource(hive: _ObservedHive(observed));
      addTearDown(() {
        if (!observed.copyGate!.isCompleted) observed.copyGate!.complete();
      });
      local.getMessages('conversation-0');
      await observed.copyStarted.future;
      final first = local.upsertMessage(
        'conversation-0',
        cacheMessage(index: 49, content: 'A first'),
      );
      final latest = local.upsertMessage(
        'conversation-0',
        cacheMessage(index: 49, content: 'A latest'),
      );
      auth.signInAs('user-b');
      final other = local.saveMessages('conversation-0', [
        cacheMessage(content: 'B'),
      ]);
      observed.copyGate!.complete();
      await Future.wait([first, latest, other]);
      expect(local.getMessages('conversation-0').single.contentText, 'B');
      local = await restart();
      auth.signInAs(cacheUserId);
      expect(local.getMessages('conversation-0').last.contentText, 'A latest');
      expect(local.getMessages('conversation-1'), hasLength(50));
      auth.signInAs('user-b');
      expect(local.getMessages('conversation-0').single.contentText, 'B');
    },
  );

  test('a failed ordinary write does not block subsequent saves', () async {
    final observed = _ObservedBox(box)..failPut = true;
    local = ChatLocalDataSource(hive: _ObservedHive(observed));
    await expectLater(
      local.saveMessages('conversation-0', [cacheMessage()]),
      throwsStateError,
    );
    observed.failPut = false;
    await local.saveMessages('conversation-0', [
      cacheMessage(content: 'Retry'),
    ]);
    local = await restart();
    expect(local.getMessages('conversation-0').single.contentText, 'Retry');
  });

  test('corrupt legacy data cannot block saving fresh messages', () async {
    await box.put('messages::$cacheUserId', '{broken');
    await local.saveMessages('conversation-0', [
      cacheMessage(content: 'Fresh'),
    ]);
    expect(box.get('messages::$cacheUserId'), '{broken');
    expect(box.containsKey(_key('conversation-0')), isTrue);
    expect(local.getMessages('conversation-0').single.contentText, 'Fresh');
  });

  test(
    'a malformed conversation does not hide healthy chats or metadata',
    () async {
      await seedLegacyChatCache(box, conversations: 2);
      await local.migrateLegacyMessages();
      await box.put(_key('conversation-0'), '{broken');
      local = ChatLocalDataSource();
      expect(local.getMessages('conversation-0'), isEmpty);
      expect(local.getConversationByTeamId('team-0')?.id, 'conversation-0');
      expect(local.getMessages('conversation-1'), hasLength(50));
    },
  );

  test(
    'keys cannot collide when user and conversation IDs contain separators',
    () async {
      auth.signInAs('a::b');
      await local.saveMessages('c', [
        cacheMessage(conversationId: 'c', content: 'First'),
      ]);
      auth.signInAs('a');
      await local.saveMessages('b::c', [
        cacheMessage(conversationId: 'b::c', content: 'Second'),
      ]);
      local = await restart();
      expect(local.getMessages('b::c').single.contentText, 'Second');
      auth.signInAs('a::b');
      expect(local.getMessages('c').single.contentText, 'First');
    },
  );

  test('a read before Hive opens can hydrate after initialization', () async {
    await local.saveMessages('conversation-0', [cacheMessage()]);
    await Hive.close();
    local = ChatLocalDataSource();
    expect(local.getMessages('conversation-0'), isEmpty);
    box = await Hive.openBox<String>(chatCacheBoxName);
    expect(local.getMessages('conversation-0'), hasLength(1));
  });

  test('migration trims each chat to its latest 50 messages', () async {
    await seedLegacyChatCache(
      box,
      conversations: 2,
      messagesPerConversation: 65,
    );
    await local.migrateLegacyMessages();
    local = await restart();
    for (final id in ['conversation-0', 'conversation-1']) {
      final messages = local.getMessages(id);
      expect(messages, hasLength(50));
      expect(messages.first.id, '$id-message-15');
      expect(messages.last.id, '$id-message-64');
    }
  });

  test('migrating one account leaves the other legacy blob intact', () async {
    await seedLegacyChatCache(box, conversations: 2);
    await seedLegacyChatCache(box, conversations: 1, scope: 'user-b');
    final otherLegacy = box.get('messages::user-b');
    await local.migrateLegacyMessages();
    expect(box.containsKey('messages::$cacheUserId'), isFalse);
    expect(box.get('messages::user-b'), otherLegacy);
    expect(box.containsKey(_key('conversation-0', 'user-b')), isFalse);
    auth.signInAs('user-b');
    expect(local.getMessages('conversation-0'), hasLength(50));
    await local.migrateLegacyMessages();
    expect(box.containsKey('messages::user-b'), isFalse);
    expect(box.containsKey(_key('conversation-0', 'user-b')), isTrue);
    expect(local.getMessages('conversation-1'), isEmpty);
  });

  test(
    'migration preserves original JSON fields and compacts only once',
    () async {
      await seedLegacyChatCache(box, conversations: 2);
      final legacy = jsonDecode(box.get('messages::$cacheUserId')!) as Map;
      (legacy['conversation-0'] as List).first['futureField'] = 'retained';
      await box.put('messages::$cacheUserId', jsonEncode(legacy));
      final observed = _ObservedBox(box);
      local = ChatLocalDataSource(hive: _ObservedHive(observed));
      await local.migrateLegacyMessages();
      expect(
        jsonDecode(box.get(_key('conversation-0'))!),
        legacy['conversation-0'],
      );
      expect(
        jsonDecode(box.get(_key('conversation-1'))!),
        legacy['conversation-1'],
      );
      expect(observed.compactions, 1);
      await local.migrateLegacyMessages();
      expect(observed.compactions, 1);
    },
  );

  test('compaction failure keeps the migrated messages durable', () async {
    await seedLegacyChatCache(box, conversations: 2);
    final observed = _ObservedBox(box)..failCompact = true;
    local = ChatLocalDataSource(hive: _ObservedHive(observed));
    await local.migrateLegacyMessages();
    expect(box.containsKey('messages::$cacheUserId'), isFalse);
    local = await restart();
    expect(local.getMessages('conversation-0'), hasLength(50));
    expect(local.getMessages('conversation-1'), hasLength(50));
  });

  test(
    'repository returns with updated memory while the real Hive write is blocked',
    () async {
      final observed = _ObservedBox(box)..putGate = Completer<void>();
      local = ChatLocalDataSource(hive: _ObservedHive(observed));
      addTearDown(() {
        if (!observed.putGate!.isCompleted) observed.putGate!.complete();
      });
      final remote = _RemotePage()..page = [cacheMessage(content: 'Fresh')];
      final repository = ChatRepositoryImpl(local, remote);
      var returned = false;
      final result = repository.getMessages('conversation-0').then((value) {
        returned = true;
        return value;
      });
      await observed.putStarted.future;
      expect(returned, isTrue);
      expect(
        repository.getCachedMessages('conversation-0').single.contentText,
        'Fresh',
      );
      expect(box.containsKey(_key('conversation-0')), isFalse);
      var flushed = false;
      final flush = local.flushPendingWrites().then((_) {
        flushed = true;
      });
      await pumpEventQueue();
      expect(flushed, isFalse);
      observed.putGate!.complete();
      await flush;
      expect(await result, same(remote.page));
      local = await restart();
      expect(local.getMessages('conversation-0').single.contentText, 'Fresh');
    },
  );

  test(
    'server-confirmed sends remain successful and readable after a disk error',
    () async {
      final observed = _ObservedBox(box)..failPut = true;
      local = ChatLocalDataSource(hive: _ObservedHive(observed));
      final repository = ChatRepositoryImpl(local, _RemotePage());
      final sent = await repository.sendMessage('conversation-0', 'Confirmed');
      await local.flushPendingWrites();
      expect(sent.contentText, 'Confirmed');
      expect(box.containsKey(_key('conversation-0')), isFalse);
      expect(
        local.getMessages('conversation-0').single.contentText,
        'Confirmed',
      );
      auth.signInAs(null);
      expect(local.getMessages('conversation-0'), isEmpty);
      auth.signInAs(cacheUserId);
      expect(
        local.getMessages('conversation-0').single.contentText,
        'Confirmed',
      );
      observed.failPut = false;
      await repository.sendMessage('conversation-0', 'Newer');
      await local.flushPendingWrites();
      local = await restart();
      expect(local.getMessages('conversation-0').single.contentText, 'Newer');
    },
  );

  test(
    'pending message snapshots survive A to B to A before disk completion',
    () async {
      final observed = _ObservedBox(box)..putGate = Completer<void>();
      local = ChatLocalDataSource(hive: _ObservedHive(observed));
      addTearDown(() {
        if (!observed.putGate!.isCompleted) observed.putGate!.complete();
      });
      final first = local.saveMessages('conversation-0', [
        cacheMessage(content: 'A first'),
      ]);
      await observed.putStarted.future;
      final last = local.saveMessages('conversation-0', [
        cacheMessage(content: 'A latest'),
      ]);
      auth.signInAs('user-b');
      final other = local.saveMessages('conversation-0', [
        cacheMessage(content: 'B'),
      ]);
      auth.signInAs(null);
      expect(local.getMessages('conversation-0'), isEmpty);
      auth.signInAs(cacheUserId);
      expect(
        local.getMessages('conversation-0').single.contentText,
        'A latest',
      );
      observed.putGate!.complete();
      await Future.wait([first, last, other]);
      local = await restart();
      expect(
        local.getMessages('conversation-0').single.contentText,
        'A latest',
      );
      auth.signInAs('user-b');
      expect(local.getMessages('conversation-0').single.contentText, 'B');
    },
  );

  test(
    'queued metadata captures the account and remains visible before persistence',
    () async {
      final observed = _ObservedBox(box)..putGate = Completer<void>();
      local = ChatLocalDataSource(hive: _ObservedHive(observed));
      addTearDown(() {
        if (!observed.putGate!.isCompleted) observed.putGate!.complete();
      });
      final team = cacheConversation();
      final saves = <Future<void>>[
        local.saveConversation(team),
        local.saveSummary(
          const ChatTeamConversationSummaryEntity(
            teamId: 'team-0',
            conversationId: 'conversation-0',
            unreadCount: 7,
            lastMessagePreview: 'A',
            lastMessageType: 'TEXT',
            lastMessageAt: null,
          ),
        ),
        local.saveDirectSummary(
          const ChatDirectConversationSummaryEntity(
            teamId: 'team-0',
            conversationId: 'direct-a',
            participantUserId: 'member',
            participantDisplayName: 'A',
            participantAvatarUrl: null,
            unreadCount: 3,
            lastMessagePreview: 'A direct',
            lastMessageType: 'TEXT',
          ),
        ),
      ];
      await observed.putStarted.future;
      auth.signInAs('user-b');
      expect(local.getConversationByTeamId('team-0'), isNull);
      expect(local.getTeamSummary('team-0'), isNull);
      saves.add(local.saveConversation(cacheConversation(index: 1)));
      auth.signInAs(cacheUserId);
      expect(local.getConversationByTeamId('team-0')?.id, team.id);
      expect(local.getTeamSummary('team-0')?.unreadCount, 7);
      expect(
        local.getDirectSummary('team-0', 'member')?.lastMessagePreview,
        'A direct',
      );
      observed.putGate!.complete();
      await Future.wait(saves);
      local = await restart();
      expect(local.getConversationByTeamId('team-0')?.id, team.id);
      expect(local.getConversationByTeamId('team-1'), isNull);
      expect(local.getTeamSummary('team-0')?.unreadCount, 7);
      expect(local.getDirectSummary('team-0', 'member')?.unreadCount, 3);
      auth.signInAs('user-b');
      expect(local.getConversationByTeamId('team-0'), isNull);
      expect(local.getConversationByTeamId('team-1')?.id, 'conversation-1');
      expect(local.getTeamSummary('team-0'), isNull);
    },
  );

  test(
    'a late server response after logout does not create anonymous cache entries',
    () async {
      final network = Completer<void>();
      addTearDown(() {
        if (!network.isCompleted) network.complete();
      });
      final remote = _RemotePage()..responseGate = network.future;
      final repository = ChatRepositoryImpl(local, remote);
      final request = repository.sendMessage('conversation-0', 'Old session');
      auth.signInAs(null);
      network.complete();
      await request;
      await local.flushPendingWrites();
      expect(local.getMessages('conversation-0'), isEmpty);
      expect(box.containsKey(_key('conversation-0', 'anonymous')), isFalse);
      expect(box.containsKey(_key('conversation-0')), isFalse);
    },
  );

  test(
    'message map snapshots are detached before deferred JSON encoding',
    () async {
      final observed = _ObservedBox(box)..putGate = Completer<void>();
      local = ChatLocalDataSource(hive: _ObservedHive(observed));
      addTearDown(() {
        if (!observed.putGate!.isCompleted) observed.putGate!.complete();
      });
      final blocker = local.saveMessages('other', []);
      await observed.putStarted.future;
      final reactions = [
        const ChatMessageReactionEntity(emoji: '👍', count: 1, mine: true),
      ];
      final message = ChatMessageEntity(
        id: 'immutable',
        conversationId: 'conversation-0',
        senderUserId: 'sender',
        senderName: 'Sender',
        senderAvatarUrl: null,
        contentText: 'Original',
        messageType: 'TEXT',
        attachmentPath: null,
        attachmentOriginalName: null,
        attachmentContentType: null,
        attachmentSizeBytes: null,
        replyTo: null,
        reactions: reactions,
        deleted: false,
        deletedAt: null,
        createdAt: DateTime.utc(2026),
        readByCurrentUser: true,
        mine: true,
      );
      final input = [message];
      final pending = local.saveMessages('conversation-0', input);
      reactions.clear();
      input.clear();
      observed.putGate!.complete();
      await Future.wait([blocker, pending]);
      local = await restart();
      expect(
        local.getMessages('conversation-0').single.reactions.single.emoji,
        '👍',
      );
    },
  );

  test(
    'server reconciliation returns while legacy migration is still blocked',
    () async {
      await seedLegacyChatCache(box, conversations: 2);
      final observed = _ObservedBox(box)..copyGate = Completer<void>();
      local = ChatLocalDataSource(hive: _ObservedHive(observed));
      addTearDown(() {
        if (!observed.copyGate!.isCompleted) observed.copyGate!.complete();
      });
      local.getMessages('conversation-0');
      await observed.copyStarted.future;
      final remote = _RemotePage()
        ..page = [cacheMessage(content: 'Server response')];
      final repository = ChatRepositoryImpl(local, remote);
      var returned = false;
      final request = repository.getMessages('conversation-0').then((messages) {
        returned = true;
        return messages;
      });
      await pumpEventQueue();
      expect(returned, isTrue);
      expect(observed.copyGate!.isCompleted, isFalse);
      expect(
        repository.getCachedMessages('conversation-0').single.contentText,
        'Server response',
      );
      observed.copyGate!.complete();
      await request;
      await local.flushPendingWrites();
      local = await restart();
      expect(
        local.getMessages('conversation-0').single.contentText,
        'Server response',
      );
      expect(local.getMessages('conversation-1'), hasLength(50));
    },
  );

  test('legacy cache is available on the first synchronous read', () async {
    await seedLegacyChatCache(box, conversations: 3);
    expect(local.getConversationByTeamId('team-0')?.id, 'conversation-0');
    expect(local.getMessages('conversation-0'), hasLength(50));
    expect(
      local.getMessages('conversation-2').last.id,
      'conversation-2-message-49',
    );
    expect(local.getMessages('missing'), isEmpty);
  });

  test(
    'messages are sorted, isolated by chat, and returned as snapshots',
    () async {
      final input = [
        cacheMessage(index: 2),
        cacheMessage(index: 0),
        cacheMessage(index: 1),
      ];
      await local.saveMessages('conversation-0', input);
      input.clear();
      final snapshot = local.getMessages('conversation-0');
      expect(snapshot.map((m) => m.id), [
        for (var i = 0; i < 3; i++) 'conversation-0-message-$i',
      ]);
      expect(() => snapshot.clear(), throwsUnsupportedError);
      await local.upsertMessage(
        'conversation-0',
        cacheMessage(index: 1, content: 'Updated'),
      );
      await local.saveMessages('conversation-1', [
        cacheMessage(conversationId: 'conversation-1'),
      ]);
      expect(snapshot[1].contentText, 'Messaggio di prova');
      expect(local.getMessages('conversation-0'), hasLength(3));
      expect(local.getMessages('conversation-0')[1].contentText, 'Updated');
      local = await restart();
      expect(local.getMessages('conversation-0')[1].contentText, 'Updated');
      expect(
        local.getMessages('conversation-1').single.conversationId,
        'conversation-1',
      );
    },
  );

  test(
    'restart retains the latest 50 messages without trimming live memory',
    () async {
      await local.saveMessages(
        'conversation-0',
        List.generate(65, (i) => cacheMessage(index: 64 - i)),
      );
      expect(local.getMessages('conversation-0'), hasLength(65));
      local = await restart();
      final messages = local.getMessages('conversation-0');
      expect(messages, hasLength(50));
      expect(messages.first.id, 'conversation-0-message-15');
      expect(messages.last.id, 'conversation-0-message-64');
    },
  );

  test('an authoritative empty page stays empty after restart', () async {
    await local.saveMessages('conversation-0', [cacheMessage()]);
    await local.saveMessages('conversation-0', []);
    local = await restart();
    expect(local.getMessages('conversation-0'), isEmpty);
  });

  test(
    'attachment, reply, reactions, deletion and read receipts survive restart',
    () async {
      final at = DateTime.utc(2026, 1, 1);
      final message = ChatMessageEntity(
        id: 'rich',
        conversationId: 'conversation-0',
        senderUserId: 'sender',
        senderName: 'Name',
        senderAvatarUrl: '/avatar',
        contentText: 'Test è 👍',
        messageType: 'FILE',
        attachmentPath: '/attachment',
        attachmentOriginalName: 'test.pdf',
        attachmentContentType: 'application/pdf',
        attachmentSizeBytes: 1024,
        replyTo: const ChatMessageReplyEntity(
          messageId: 'parent',
          senderName: 'Parent',
          contentPreview: 'Preview',
          messageType: 'TEXT',
          deleted: true,
        ),
        reactions: const [
          ChatMessageReactionEntity(emoji: '👍', count: 2, mine: true),
        ],
        deleted: true,
        deletedAt: at,
        createdAt: at,
        readByCurrentUser: true,
        deliveredByOtherCount: 3,
        readByOtherCount: 2,
        mine: true,
      );
      await local.upsertMessage('conversation-0', message);
      local = await restart();
      final saved = local.getMessages('conversation-0').single;
      expect(
        [
          saved.id,
          saved.conversationId,
          saved.senderUserId,
          saved.senderName,
          saved.senderAvatarUrl,
          saved.contentText,
          saved.messageType,
          saved.attachmentPath,
          saved.attachmentOriginalName,
          saved.attachmentContentType,
          saved.attachmentSizeBytes,
          saved.deleted,
          saved.deletedAt,
          saved.createdAt,
          saved.readByCurrentUser,
          saved.deliveredByOtherCount,
          saved.readByOtherCount,
          saved.mine,
        ],
        [
          'rich',
          'conversation-0',
          'sender',
          'Name',
          '/avatar',
          'Test è 👍',
          'FILE',
          '/attachment',
          'test.pdf',
          'application/pdf',
          1024,
          true,
          at,
          at,
          true,
          3,
          2,
          true,
        ],
      );
      expect(
        [
          saved.replyTo?.messageId,
          saved.replyTo?.senderName,
          saved.replyTo?.contentPreview,
          saved.replyTo?.messageType,
          saved.replyTo?.deleted,
        ],
        ['parent', 'Parent', 'Preview', 'TEXT', true],
      );
      expect(
        [
          saved.reactions.single.emoji,
          saved.reactions.single.count,
          saved.reactions.single.mine,
        ],
        ['👍', 2, true],
      );
    },
  );

  test('team and direct metadata and summaries survive restart', () async {
    final team = cacheConversation();
    await local.saveConversation(team);
    await local.saveConversation(
      ChatConversationEntity(
        id: 'direct',
        teamId: 'team-0',
        type: 'DIRECT',
        createdAt: team.createdAt,
        updatedAt: team.updatedAt,
        participantUserId: 'member',
        participantDisplayName: 'Member',
        participantAvatarUrl: '/member',
        lastMessageAt: team.lastMessageAt,
      ),
    );
    await local.saveSummary(
      ChatTeamConversationSummaryEntity(
        teamId: 'team-0',
        conversationId: team.id,
        unreadCount: 4,
        lastMessagePreview: 'Team preview',
        lastMessageType: 'TEXT',
        lastMessageAt: team.lastMessageAt,
      ),
    );
    await local.saveDirectSummary(
      ChatDirectConversationSummaryEntity(
        teamId: 'team-0',
        conversationId: 'direct',
        participantUserId: 'member',
        participantDisplayName: 'Member',
        participantAvatarUrl: '/member',
        unreadCount: 2,
        lastMessagePreview: 'Direct preview',
        lastMessageType: 'FILE',
        lastMessageAt: team.lastMessageAt,
      ),
    );
    local = await restart();
    expect(
      local.getConversationByTeamId('team-0')?.lastMessageAt,
      team.lastMessageAt,
    );
    expect(local.getDirectConversation('team-0', 'member')?.id, 'direct');
    expect(local.getDirectConversation('team-0', 'other'), isNull);
    expect(local.getTeamSummary('team-0')?.unreadCount, 4);
    expect(local.getTeamSummary('team-0')?.lastMessagePreview, 'Team preview');
    expect(local.getDirectSummary('team-0', 'member')?.unreadCount, 2);
    expect(
      local.getDirectSummary('team-0', 'member')?.lastMessagePreview,
      'Direct preview',
    );
  });

  ChatDirectConversationSummaryEntity directSummary(int index) =>
      ChatDirectConversationSummaryEntity(
        teamId: 'team-0',
        conversationId: 'direct-$index',
        participantUserId: 'member-$index',
        participantDisplayName: 'Member $index',
        participantAvatarUrl: null,
        unreadCount: index,
        lastMessagePreview: 'Preview $index',
        lastMessageType: 'TEXT',
      );

  test('a burst of summary saves writes the list once, not once per save', () async {
    final observed = _ObservedBox(box);
    local = ChatLocalDataSource(hive: _ObservedHive(observed));

    final saves = [
      for (var i = 0; i < 50; i++) local.saveDirectSummary(directSummary(i)),
    ];
    // Memory is current before any disk work happens.
    expect(local.getDirectSummary('team-0', 'member-49')?.unreadCount, 49);
    await Future.wait(saves);

    expect(
      observed.writes.where((key) => key == 'direct_summaries::$cacheUserId'),
      hasLength(1),
    );
    local = await restart();
    for (var i = 0; i < 50; i++) {
      expect(local.getDirectSummary('team-0', 'member-$i')?.unreadCount, i);
    }
  });

  test('a superseded write does not stop the newest snapshot being saved', () async {
    final observed = _ObservedBox(box);
    local = ChatLocalDataSource(hive: _ObservedHive(observed));
    final first = local.saveDirectSummary(directSummary(1));
    final second = local.saveDirectSummary(directSummary(2));
    await Future.wait([first, second]);

    local = await restart();
    expect(local.getDirectSummary('team-0', 'member-1')?.unreadCount, 1);
    expect(local.getDirectSummary('team-0', 'member-2')?.unreadCount, 2);
  });

  test('a failed newest write keeps its snapshot readable and retriable', () async {
    final observed = _ObservedBox(box)..failPut = true;
    local = ChatLocalDataSource(hive: _ObservedHive(observed));
    final first = local.saveDirectSummary(directSummary(1));
    final second = local.saveDirectSummary(directSummary(2));
    await first; // superseded: completes without touching the disk
    await expectLater(second, throwsStateError);
    expect(local.getDirectSummary('team-0', 'member-2')?.unreadCount, 2);

    observed.failPut = false;
    await local.saveDirectSummary(directSummary(3));
    local = await restart();
    expect(local.getDirectSummary('team-0', 'member-3')?.unreadCount, 3);
    expect(local.getDirectSummary('team-0', 'member-2')?.unreadCount, 2);
  });

  test('upserting before Hive opens merges into the stored history', () async {
    await local.saveMessages('conversation-0', [
      for (var i = 0; i < 3; i++) cacheMessage(index: i),
    ]);
    local = await restart();
    await Hive.close();

    local = ChatLocalDataSource();
    final upsert = local.upsertMessage(
      'conversation-0',
      cacheMessage(index: 3),
    );
    // No one-message list is published while the stored history is unknown.
    expect(local.getMessages('conversation-0'), isEmpty);
    await upsert;

    expect(
      local.getMessages('conversation-0').map((m) => m.id),
      List.generate(4, (i) => 'conversation-0-message-$i'),
    );
    local = await restart();
    expect(
      local.getMessages('conversation-0').map((m) => m.id),
      List.generate(4, (i) => 'conversation-0-message-$i'),
    );
  });

  test('upserting before Hive opens replaces a stored message by id', () async {
    await local.saveMessages('conversation-0', [
      cacheMessage(index: 0),
      cacheMessage(index: 1, content: 'Old'),
    ]);
    local = await restart();
    await Hive.close();

    local = ChatLocalDataSource();
    await local.upsertMessage(
      'conversation-0',
      cacheMessage(index: 1, content: 'Edited'),
    );

    local = await restart();
    final messages = local.getMessages('conversation-0');
    expect(messages, hasLength(2));
    expect(messages.last.contentText, 'Edited');
  });

  test('upserting before Hive opens keeps only the latest 50 messages', () async {
    await local.saveMessages('conversation-0', [
      for (var i = 0; i < 50; i++) cacheMessage(index: i),
    ]);
    local = await restart();
    await Hive.close();

    local = ChatLocalDataSource();
    await local.upsertMessage('conversation-0', cacheMessage(index: 50));

    local = await restart();
    final messages = local.getMessages('conversation-0');
    expect(messages, hasLength(50));
    expect(messages.first.id, 'conversation-0-message-1');
    expect(messages.last.id, 'conversation-0-message-50');
  });

  test(
    'user switch and logout isolate memory and disk for identical chat IDs',
    () async {
      await local.saveConversation(cacheConversation());
      await local.saveMessages('conversation-0', [
        cacheMessage(content: 'User A'),
      ]);
      auth.signInAs('cache-user-b');
      expect(local.getConversationByTeamId('team-0'), isNull);
      expect(local.getMessages('conversation-0'), isEmpty);
      await local.saveMessages('conversation-0', [
        cacheMessage(content: 'User B'),
      ]);
      auth.signInAs(null);
      expect(local.getMessages('conversation-0'), isEmpty);
      auth.signInAs(cacheUserId);
      expect(local.getMessages('conversation-0').single.contentText, 'User A');
      expect(local.getConversationByTeamId('team-0')?.id, 'conversation-0');
      local = await restart();
      expect(local.getMessages('conversation-0').single.contentText, 'User A');
      auth.signInAs('cache-user-b');
      expect(local.getMessages('conversation-0').single.contentText, 'User B');
    },
  );

  test(
    'malformed legacy JSON produces a cache miss instead of throwing',
    () async {
      await box.put('messages::$cacheUserId', '{broken');
      expect(local.getMessages('conversation-0'), isEmpty);
    },
  );

  test(
    'repository reconciliation replaces the first page; older pages do not overwrite it',
    () async {
      final remote = _RemotePage();
      final repository = ChatRepositoryImpl(local, remote);
      await local.saveMessages('conversation-0', [
        cacheMessage(content: 'Stale'),
      ]);
      remote.page = [cacheMessage(index: 10, content: 'Fresh')];
      await repository.getMessages('conversation-0');
      remote.page = [cacheMessage(index: 1, content: 'Older')];
      final older = await repository.getMessages(
        'conversation-0',
        before: DateTime.utc(2026, 1, 1, 0, 0, 10),
      );
      expect(older.single.contentText, 'Older');
      expect(
        repository.getCachedMessages('conversation-0').single.contentText,
        'Fresh',
      );
      local = await restart();
      expect(local.getMessages('conversation-0').single.contentText, 'Fresh');
    },
  );
}
