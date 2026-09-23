import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_message_report_reason.dart';
import 'package:note_sondage/feature/chat/infrastructure/data_source/chat_remote_data_source.dart';

class _FakeHttpClientAdapter implements HttpClientAdapter {
  RequestOptions? lastRequest;
  String responseBody = '{}';
  int statusCode = 200;
  Object? errorToThrow;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return ResponseBody.fromString(
      responseBody,
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _FakeHttpClientAdapter adapter;
  late ChatRemoteDataSource dataSource;

  setUp(() {
    adapter = _FakeHttpClientAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
      ..httpClientAdapter = adapter;
    dataSource = ChatRemoteDataSource(dio: dio);
  });

  Matcher wrapsWith(String prefix) => isA<Exception>().having(
    (error) => error.toString(),
    'message',
    contains(prefix),
  );

  group('happy paths still parse the response', () {
    test('getOrCreateTeamConversation', () async {
      adapter.responseBody = jsonEncode({'id': 'conversation-1'});

      final result = await dataSource.getOrCreateTeamConversation('team-1');

      expect(result.id, 'conversation-1');
    });

    test('getTeamConversationSummary', () async {
      adapter.responseBody = jsonEncode({'teamId': 'team-1'});

      final result = await dataSource.getTeamConversationSummary('team-1');

      expect(result.teamId, 'team-1');
    });

    test('getOrCreateDirectConversation', () async {
      adapter.responseBody = jsonEncode({'id': 'conversation-1'});

      final result = await dataSource.getOrCreateDirectConversation(
        'team-1',
        'member-1',
      );

      expect(result.id, 'conversation-1');
    });

    test('getDirectConversationSummary', () async {
      adapter.responseBody = jsonEncode({'participantUserId': 'member-1'});

      final result = await dataSource.getDirectConversationSummary(
        'team-1',
        'member-1',
      );

      expect(result.participantUserId, 'member-1');
    });

    test('getMessages', () async {
      adapter.responseBody = jsonEncode([
        {'id': 'message-1'},
      ]);

      final result = await dataSource.getMessages('conversation-1');

      expect(result.single.id, 'message-1');
    });

    test('sendMessage', () async {
      adapter.responseBody = jsonEncode({'id': 'message-1'});

      final result = await dataSource.sendMessage('conversation-1', 'Ciao');

      expect(result.id, 'message-1');
    });

    test('sendAttachmentMessage', () async {
      adapter.responseBody = jsonEncode({'id': 'message-1'});

      final result = await dataSource.sendAttachmentMessage(
        'conversation-1',
        bytes: const [1, 2, 3],
        fileName: 'photo.png',
        contentType: 'image/png',
      );

      expect(result.id, 'message-1');
    });

    test('markConversationRead', () async {
      adapter.responseBody = '{}';

      await dataSource.markConversationRead('conversation-1');

      expect(adapter.lastRequest!.method, 'POST');
    });

    test('toggleReaction', () async {
      adapter.responseBody = jsonEncode({'id': 'message-1'});

      final result = await dataSource.toggleReaction('message-1', '👍');

      expect(result.id, 'message-1');
    });

    test('deleteMessage', () async {
      adapter.responseBody = jsonEncode({'id': 'message-1', 'deleted': true});

      final result = await dataSource.deleteMessage('message-1');

      expect(result.deleted, isTrue);
    });

    test('blockSender', () async {
      adapter.responseBody = jsonEncode({
        'userId': 'user-2',
        'displayName': 'User Two',
        'blockedAt': '2026-01-01T00:00:00.000',
      });

      final result = await dataSource.blockSender('message-1');

      expect(result.userId, 'user-2');
      expect(result.displayName, 'User Two');
      expect(
        adapter.lastRequest?.path,
        contains('/api/chat/messages/message-1/block-sender'),
      );
    });

    test('unblockUser', () async {
      await dataSource.unblockUser('user-2');

      expect(
        adapter.lastRequest?.path,
        contains('/api/chat/blocked-users/user-2'),
      );
      expect(adapter.lastRequest?.method, 'DELETE');
    });

    test('getBlockedUsers', () async {
      adapter.responseBody = jsonEncode([
        {'userId': 'user-2', 'displayName': 'User Two'},
      ]);

      final result = await dataSource.getBlockedUsers();

      expect(result.single.userId, 'user-2');
    });

    test('reportMessage sends the reason wire value and trimmed comment', () async {
      await dataSource.reportMessage(
        'message-1',
        reason: ChatMessageReportReason.hateSpeech,
        comment: '  looks bad  ',
      );

      expect(
        adapter.lastRequest?.path,
        contains('/api/chat/messages/message-1/report'),
      );
      expect(adapter.lastRequest?.data, {
        'reason': 'HATE_SPEECH',
        'comment': 'looks bad',
      });
    });

    test('reportMessage omits a blank comment', () async {
      await dataSource.reportMessage(
        'message-1',
        reason: ChatMessageReportReason.spam,
        comment: '   ',
      );

      expect(adapter.lastRequest?.data, {'reason': 'SPAM'});
    });
  });

  group('transport failures are wrapped with a descriptive message', () {
    test('getOrCreateTeamConversation', () async {
      adapter.errorToThrow = Exception('boom');

      await expectLater(
        dataSource.getOrCreateTeamConversation('team-1'),
        throwsA(wrapsWith('Failed to fetch team conversation:')),
      );
    });

    test('getTeamConversationSummary', () async {
      adapter.errorToThrow = Exception('boom');

      await expectLater(
        dataSource.getTeamConversationSummary('team-1'),
        throwsA(wrapsWith('Failed to fetch team conversation summary:')),
      );
    });

    test('getOrCreateDirectConversation', () async {
      adapter.errorToThrow = Exception('boom');

      await expectLater(
        dataSource.getOrCreateDirectConversation('team-1', 'member-1'),
        throwsA(wrapsWith('Failed to fetch direct conversation:')),
      );
    });

    test('getDirectConversationSummary', () async {
      adapter.errorToThrow = Exception('boom');

      await expectLater(
        dataSource.getDirectConversationSummary('team-1', 'member-1'),
        throwsA(wrapsWith('Failed to fetch direct conversation summary:')),
      );
    });

    test('getMessages', () async {
      adapter.errorToThrow = Exception('boom');

      await expectLater(
        dataSource.getMessages('conversation-1'),
        throwsA(wrapsWith('Failed to fetch messages:')),
      );
    });

    test('sendMessage', () async {
      adapter.errorToThrow = Exception('boom');

      await expectLater(
        dataSource.sendMessage('conversation-1', 'Ciao'),
        throwsA(wrapsWith('Failed to send message:')),
      );
    });

    test('sendAttachmentMessage', () async {
      adapter.errorToThrow = Exception('boom');

      await expectLater(
        dataSource.sendAttachmentMessage(
          'conversation-1',
          bytes: const [1, 2, 3],
          fileName: 'photo.png',
          contentType: 'image/png',
        ),
        throwsA(wrapsWith('Failed to send attachment message:')),
      );
    });

    test('markConversationRead', () async {
      adapter.errorToThrow = Exception('boom');

      await expectLater(
        dataSource.markConversationRead('conversation-1'),
        throwsA(wrapsWith('Failed to mark conversation as read:')),
      );
    });

    test('toggleReaction', () async {
      adapter.errorToThrow = Exception('boom');

      await expectLater(
        dataSource.toggleReaction('message-1', '👍'),
        throwsA(wrapsWith('Failed to toggle reaction:')),
      );
    });

    test('deleteMessage', () async {
      adapter.errorToThrow = Exception('boom');

      await expectLater(
        dataSource.deleteMessage('message-1'),
        throwsA(wrapsWith('Failed to delete message:')),
      );
    });

    test('blockSender', () async {
      adapter.errorToThrow = Exception('boom');

      await expectLater(
        dataSource.blockSender('message-1'),
        throwsA(wrapsWith('Failed to block sender:')),
      );
    });

    test('unblockUser', () async {
      adapter.errorToThrow = Exception('boom');

      await expectLater(
        dataSource.unblockUser('user-2'),
        throwsA(wrapsWith('Failed to unblock user:')),
      );
    });

    test('getBlockedUsers', () async {
      adapter.errorToThrow = Exception('boom');

      await expectLater(
        dataSource.getBlockedUsers(),
        throwsA(wrapsWith('Failed to fetch blocked users:')),
      );
    });

    test('reportMessage', () async {
      adapter.errorToThrow = Exception('boom');

      await expectLater(
        dataSource.reportMessage(
          'message-1',
          reason: ChatMessageReportReason.spam,
        ),
        throwsA(wrapsWith('Failed to report message:')),
      );
    });
  });
}
