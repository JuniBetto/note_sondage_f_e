import 'package:flutter_test/flutter_test.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_message_action_entity.dart';
import 'package:note_sondage/feature/chat/domain/repositories/chat_message_action_repository.dart';
import 'package:note_sondage/feature/chat/domain/use_case/chat_message_action_use_case.dart';

class _FakeChatMessageActionRepository implements ChatMessageActionRepository {
  Future<ChatMessageActionDraftResult> Function({
    required ChatMessageActionType actionType,
    required String conversationId,
    required String messageId,
    required String teamId,
    required String locale,
    String? selectedMessageText,
    String? memberUserId,
    String? memberDisplayName,
  })?
  buildDraftHandler;

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
  }) {
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
    return buildDraftHandler!(
      actionType: actionType,
      conversationId: conversationId,
      messageId: messageId,
      teamId: teamId,
      locale: locale,
      selectedMessageText: selectedMessageText,
      memberUserId: memberUserId,
      memberDisplayName: memberDisplayName,
    );
  }
}

void main() {
  late _FakeChatMessageActionRepository repository;
  late ChatMessageActionUseCase useCase;

  setUp(() {
    repository = _FakeChatMessageActionRepository();
    useCase = ChatMessageActionUseCase(repository);
  });

  test('buildDraft forwards every argument to the repository', () async {
    const result = ChatMessageActionDraftResult(
      messageActionType: 'create_task',
      resolutionStatus: 'ok',
      targetEntityType: 'TASK',
      warnings: [],
    );
    repository.buildDraftHandler = ({
      required actionType,
      required conversationId,
      required messageId,
      required teamId,
      required locale,
      selectedMessageText,
      memberUserId,
      memberDisplayName,
    }) async => result;

    final returned = await useCase.buildDraft(
      actionType: ChatMessageActionType.createTask,
      conversationId: 'conversation-1',
      messageId: 'message-1',
      teamId: 'team-1',
      locale: 'it',
      selectedMessageText: 'Compra il latte',
      memberUserId: 'member-1',
      memberDisplayName: 'Mario Rossi',
    );

    expect(returned, same(result));
    expect(repository.buildDraftCalls, [
      (
        actionType: ChatMessageActionType.createTask,
        conversationId: 'conversation-1',
        messageId: 'message-1',
        teamId: 'team-1',
        locale: 'it',
        selectedMessageText: 'Compra il latte',
        memberUserId: 'member-1',
        memberDisplayName: 'Mario Rossi',
      ),
    ]);
  });

  test('buildDraft forwards null optional fields as-is', () async {
    const result = ChatMessageActionDraftResult(
      messageActionType: 'create_sondage',
      resolutionStatus: 'unsupported',
      targetEntityType: 'SONDAGE',
      warnings: [],
    );
    repository.buildDraftHandler = ({
      required actionType,
      required conversationId,
      required messageId,
      required teamId,
      required locale,
      selectedMessageText,
      memberUserId,
      memberDisplayName,
    }) async => result;

    await useCase.buildDraft(
      actionType: ChatMessageActionType.createSondage,
      conversationId: 'conversation-1',
      messageId: 'message-1',
      teamId: 'team-1',
      locale: 'it',
    );

    final call = repository.buildDraftCalls.single;
    expect(call.selectedMessageText, isNull);
    expect(call.memberUserId, isNull);
    expect(call.memberDisplayName, isNull);
  });

  test('buildDraft propagates repository errors', () async {
    repository.buildDraftHandler = ({
      required actionType,
      required conversationId,
      required messageId,
      required teamId,
      required locale,
      selectedMessageText,
      memberUserId,
      memberDisplayName,
    }) => Future<ChatMessageActionDraftResult>.error(
      Exception('workflow unreachable'),
    );

    await expectLater(
      useCase.buildDraft(
        actionType: ChatMessageActionType.createEvent,
        conversationId: 'conversation-1',
        messageId: 'message-1',
        teamId: 'team-1',
        locale: 'it',
      ),
      throwsA(isA<Exception>()),
    );
  });
}
