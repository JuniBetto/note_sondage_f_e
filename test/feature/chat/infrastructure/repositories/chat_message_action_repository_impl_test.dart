import 'package:flutter_test/flutter_test.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_message_action_entity.dart';
import 'package:note_sondage/feature/chat/infrastructure/data_source/chat_message_action_remote_data_source.dart';
import 'package:note_sondage/feature/chat/infrastructure/repositories/chat_message_action_repository_impl.dart';

class _FakeChatMessageActionRemoteDataSource
    extends ChatMessageActionRemoteDataSource {
  ChatMessageActionDraftResult? result;
  Object? error;

  final buildDraftCalls =
      <({
        ChatMessageActionType actionType,
        String conversationId,
        String messageId,
        String teamId,
        String locale,
        String? selectedMessageText,
        String? memberUserId,
        String? memberDisplayName,
      })>[];

  @override
  Future<ChatMessageActionDraftResult> buildDraft({
    required ChatMessageActionType actionType,
    required String conversationId,
    required String messageId,
    required String teamId,
    required String locale,
    String? selectedMessageText,
    String? memberUserId,
    String? memberDisplayName,
  }) async {
    buildDraftCalls.add((
      actionType: actionType,
      conversationId: conversationId,
      messageId: messageId,
      teamId: teamId,
      locale: locale,
      selectedMessageText: selectedMessageText,
      memberUserId: memberUserId,
      memberDisplayName: memberDisplayName,
    ));
    if (error != null) {
      throw error!;
    }
    return result!;
  }
}

void main() {
  late _FakeChatMessageActionRemoteDataSource remote;
  late ChatMessageActionRepositoryImpl repository;

  setUp(() {
    remote = _FakeChatMessageActionRemoteDataSource();
    repository = ChatMessageActionRepositoryImpl(remote);
  });

  test('buildDraft forwards every argument to the remote data source', () async {
    const result = ChatMessageActionDraftResult(
      messageActionType: 'create_shift',
      resolutionStatus: 'ok',
      targetEntityType: 'SHIFT',
      warnings: [],
    );
    remote.result = result;

    final returned = await repository.buildDraft(
      actionType: ChatMessageActionType.createShift,
      conversationId: 'conversation-1',
      messageId: 'message-1',
      teamId: 'team-1',
      locale: 'it',
      selectedMessageText: 'Turno di domani',
      memberUserId: 'member-1',
      memberDisplayName: 'Mario Rossi',
    );

    expect(returned, same(result));
    expect(remote.buildDraftCalls, [
      (
        actionType: ChatMessageActionType.createShift,
        conversationId: 'conversation-1',
        messageId: 'message-1',
        teamId: 'team-1',
        locale: 'it',
        selectedMessageText: 'Turno di domani',
        memberUserId: 'member-1',
        memberDisplayName: 'Mario Rossi',
      ),
    ]);
  });

  test('buildDraft propagates remote errors', () async {
    remote.error = Exception('Invalid workflow action response');

    await expectLater(
      repository.buildDraft(
        actionType: ChatMessageActionType.createTask,
        conversationId: 'conversation-1',
        messageId: 'message-1',
        teamId: 'team-1',
        locale: 'it',
      ),
      throwsA(isA<Exception>()),
    );
  });
}
