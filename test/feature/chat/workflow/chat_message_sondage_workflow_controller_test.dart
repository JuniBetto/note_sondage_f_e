import 'package:flutter_test/flutter_test.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_conversation_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_message_action_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_message_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_message_reaction_entity.dart';
import 'package:note_sondage/feature/chat/domain/repositories/chat_message_action_repository.dart';
import 'package:note_sondage/feature/chat/domain/use_case/chat_message_action_use_case.dart';
import 'package:note_sondage/feature/chat/workflow/chat_message_sondage_workflow_controller.dart';
import 'package:note_sondage/feature/sondage/ui/widgets/sondage_create_prefill.dart';

class _UnreachableChatMessageActionRepository
    implements ChatMessageActionRepository {
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
  }) => throw UnimplementedError();
}

class _FakeChatMessageActionUseCase extends ChatMessageActionUseCase {
  _FakeChatMessageActionUseCase({required this.result})
    : super(_UnreachableChatMessageActionRepository());

  final ChatMessageActionDraftResult result;

  ChatMessageActionType? capturedActionType;
  String? capturedConversationId;
  String? capturedMessageId;
  String? capturedTeamId;
  String? capturedLocale;
  String? capturedSelectedMessageText;
  String? capturedMemberUserId;
  String? capturedMemberDisplayName;

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
    capturedActionType = actionType;
    capturedConversationId = conversationId;
    capturedMessageId = messageId;
    capturedTeamId = teamId;
    capturedLocale = locale;
    capturedSelectedMessageText = selectedMessageText;
    capturedMemberUserId = memberUserId;
    capturedMemberDisplayName = memberDisplayName;
    return result;
  }
}

void main() {
  late _FakeChatMessageActionUseCase draftService;
  late ChatMessageSondageWorkflowController controller;

  setUp(() {
    draftService = _FakeChatMessageActionUseCase(
      result: const ChatMessageActionDraftResult(
        messageActionType: 'create_sondage',
        resolutionStatus: 'ready',
        targetEntityType: 'sondage',
        warnings: <ChatMessageActionWarning>[],
        sondagePrefill: SondageCreatePrefill(
          question: 'Chi è disponibile sabato?',
          options: <String>['Disponibile', 'Non disponibile'],
          teamId: 'team-1',
        ),
      ),
    );
    controller = ChatMessageSondageWorkflowController(
      draftService: draftService,
    );
  });

  group('ChatMessageSondageWorkflowController', () {
    test('prepareDraft delegates create-survey draft generation', () async {
      final conversation = ChatConversationEntity(
        id: 'conv-1',
        teamId: 'team-1',
        type: 'TEAM',
        createdAt: DateTime(2026, 8, 26),
        updatedAt: DateTime(2026, 8, 26),
      );
      final message = ChatMessageEntity(
        id: 'msg-1',
        conversationId: 'conv-1',
        senderUserId: 'user-1',
        senderName: 'Arthur',
        senderAvatarUrl: null,
        contentText: 'Chi può coprire sabato mattina?',
        messageType: 'TEXT',
        attachmentPath: null,
        attachmentOriginalName: null,
        attachmentContentType: null,
        attachmentSizeBytes: null,
        replyTo: null,
        reactions: <ChatMessageReactionEntity>[],
        deleted: false,
        deletedAt: null,
        createdAt: DateTime(2026, 8, 26),
        readByCurrentUser: true,
        mine: false,
      );

      final result = await controller.prepareDraft(
        conversation: conversation,
        message: message,
        teamId: 'team-1',
        locale: 'it',
        memberUserId: 'user-2',
        memberDisplayName: 'Mario',
      );

      expect(result, same(draftService.result));
      expect(
        draftService.capturedActionType,
        ChatMessageActionType.createSondage,
      );
      expect(draftService.capturedConversationId, 'conv-1');
      expect(draftService.capturedMessageId, 'msg-1');
      expect(draftService.capturedTeamId, 'team-1');
      expect(draftService.capturedLocale, 'it');
      expect(
        draftService.capturedSelectedMessageText,
        'Chi può coprire sabato mattina?',
      );
      expect(draftService.capturedMemberUserId, 'user-2');
      expect(draftService.capturedMemberDisplayName, 'Mario');
    });
  });
}
