import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_message_action_entity.dart';
import 'package:note_sondage/feature/chat/infrastructure/data_source/chat_message_action_remote_data_source.dart';

class _FakeHttpClientAdapter implements HttpClientAdapter {
  RequestOptions? lastRequest;
  String responseBody = '{}';
  int statusCode = 200;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
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
  late ChatMessageActionRemoteDataSource dataSource;

  setUp(() {
    adapter = _FakeHttpClientAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
      ..httpClientAdapter = adapter;
    dataSource = ChatMessageActionRemoteDataSource(dio: dio);
  });

  test('buildDraft posts to the workflow draft endpoint', () async {
    adapter.responseBody = jsonEncode({
      'messageActionType': 'create_task',
      'resolutionStatus': 'ok',
      'targetEntityType': 'TASK',
      'warnings': <dynamic>[],
    });

    await dataSource.buildDraft(
      actionType: ChatMessageActionType.createTask,
      conversationId: 'conversation-1',
      messageId: 'message-1',
      teamId: 'team-1',
      locale: 'it',
    );

    expect(
      adapter.lastRequest!.uri.toString(),
      'https://example.test/api/aggregate/workflow/message-actions/draft',
    );
    expect(adapter.lastRequest!.method, 'POST');
  });

  test('buildDraft maps each action type to its backend wire value', () async {
    adapter.responseBody = jsonEncode({
      'messageActionType': 'create_sondage',
      'resolutionStatus': 'ok',
      'targetEntityType': 'SONDAGE',
      'warnings': <dynamic>[],
    });

    const expectedWireValues = {
      ChatMessageActionType.createSondage: 'create_sondage',
      ChatMessageActionType.createShift: 'create_shift',
      ChatMessageActionType.createTask: 'create_task',
      ChatMessageActionType.createEvent: 'create_event',
    };

    for (final entry in expectedWireValues.entries) {
      await dataSource.buildDraft(
        actionType: entry.key,
        conversationId: 'conversation-1',
        messageId: 'message-1',
        teamId: 'team-1',
        locale: 'it',
      );

      final payload = adapter.lastRequest!.data as Map<String, dynamic>;
      expect(payload['messageActionType'], entry.value);
    }
  });

  test(
    'buildDraft omits selectedMessageText when blank and trims it otherwise',
    () async {
      adapter.responseBody = jsonEncode({
        'messageActionType': 'create_task',
        'resolutionStatus': 'ok',
        'targetEntityType': 'TASK',
        'warnings': <dynamic>[],
      });

      await dataSource.buildDraft(
        actionType: ChatMessageActionType.createTask,
        conversationId: 'conversation-1',
        messageId: 'message-1',
        teamId: 'team-1',
        locale: 'it',
        selectedMessageText: '   ',
      );
      var payload = adapter.lastRequest!.data as Map<String, dynamic>;
      expect(payload.containsKey('selectedMessageText'), isFalse);

      await dataSource.buildDraft(
        actionType: ChatMessageActionType.createTask,
        conversationId: 'conversation-1',
        messageId: 'message-1',
        teamId: 'team-1',
        locale: 'it',
        selectedMessageText: '  Compra il latte  ',
      );
      payload = adapter.lastRequest!.data as Map<String, dynamic>;
      expect(payload['selectedMessageText'], 'Compra il latte');
    },
  );

  test(
    'buildDraft marks the clientContext as TEAM when no member is targeted',
    () async {
      adapter.responseBody = jsonEncode({
        'messageActionType': 'create_task',
        'resolutionStatus': 'ok',
        'targetEntityType': 'TASK',
        'warnings': <dynamic>[],
      });

      await dataSource.buildDraft(
        actionType: ChatMessageActionType.createTask,
        conversationId: 'conversation-1',
        messageId: 'message-1',
        teamId: 'team-1',
        locale: 'it',
      );

      final payload = adapter.lastRequest!.data as Map<String, dynamic>;
      final clientContext = payload['clientContext'] as Map<String, dynamic>;
      expect(clientContext['chatType'], 'TEAM');
      expect(clientContext.containsKey('memberUserId'), isFalse);
      expect(clientContext.containsKey('memberDisplayName'), isFalse);
    },
  );

  test(
    'buildDraft marks the clientContext as DIRECT and trims member fields '
    'when a member is targeted',
    () async {
      adapter.responseBody = jsonEncode({
        'messageActionType': 'create_task',
        'resolutionStatus': 'ok',
        'targetEntityType': 'TASK',
        'warnings': <dynamic>[],
      });

      await dataSource.buildDraft(
        actionType: ChatMessageActionType.createTask,
        conversationId: 'conversation-1',
        messageId: 'message-1',
        teamId: 'team-1',
        locale: 'it',
        memberUserId: '  member-1  ',
        memberDisplayName: '  Mario Rossi  ',
      );

      final payload = adapter.lastRequest!.data as Map<String, dynamic>;
      final clientContext = payload['clientContext'] as Map<String, dynamic>;
      expect(clientContext['chatType'], 'DIRECT');
      expect(clientContext['memberUserId'], 'member-1');
      expect(clientContext['memberDisplayName'], 'Mario Rossi');
    },
  );

  test('buildDraft parses a well-formed JSON object response', () async {
    adapter.responseBody = jsonEncode({
      'messageActionType': 'create_task',
      'resolutionStatus': 'ok',
      'targetEntityType': 'TASK',
      'warnings': <dynamic>[],
    });

    final result = await dataSource.buildDraft(
      actionType: ChatMessageActionType.createTask,
      conversationId: 'conversation-1',
      messageId: 'message-1',
      teamId: 'team-1',
      locale: 'it',
    );

    expect(result.messageActionType, 'create_task');
    expect(result.resolutionStatus, 'ok');
    expect(result.targetEntityType, 'TASK');
  });

  test(
    'buildDraft throws when the backend response is not a JSON object',
    () async {
      adapter.responseBody = jsonEncode(<dynamic>[1, 2, 3]);

      await expectLater(
        dataSource.buildDraft(
          actionType: ChatMessageActionType.createTask,
          conversationId: 'conversation-1',
          messageId: 'message-1',
          teamId: 'team-1',
          locale: 'it',
        ),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('Invalid workflow action response'),
          ),
        ),
      );
    },
  );
}
