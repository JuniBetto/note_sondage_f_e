import 'package:flutter/material.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_conversation_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_message_action_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_message_entity.dart';
import 'package:note_sondage/feature/chat/domain/use_case/chat_message_action_use_case.dart';
import 'package:note_sondage/feature/sondage/ui/mobile/widgets/create_sondage_mobile.dart';
import 'package:note_sondage/feature/sondage/ui/web/widgets/create_sondage_web.dart';
import 'package:note_sondage/feature/sondage/ui/widgets/sondage_create_prefill.dart';
import 'package:note_sondage/ui/widgets/custom_dialog.dart';

class ChatMessageSondageWorkflowController {
  ChatMessageSondageWorkflowController({
    required ChatMessageActionUseCase draftService,
  }) : _draftService = draftService;

  final ChatMessageActionUseCase _draftService;

  Future<ChatMessageActionDraftResult> prepareDraft({
    required ChatConversationEntity conversation,
    required ChatMessageEntity message,
    required String teamId,
    required String locale,
    String? memberUserId,
    String? memberDisplayName,
  }) {
    return _draftService.buildDraft(
      actionType: ChatMessageActionType.createSondage,
      conversationId: conversation.id,
      messageId: message.id,
      teamId: teamId,
      locale: locale,
      selectedMessageText: message.contentText,
      memberUserId: memberUserId,
      memberDisplayName: memberDisplayName,
    );
  }

  Future<void> openDraft({
    required BuildContext context,
    required SondageCreatePrefill prefill,
    required bool useMobileLayout,
  }) async {
    if (useMobileLayout) {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => FractionallySizedBox(
          heightFactor: 0.94,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: CreateSondageMobile(
              initialPrefill: prefill,
              enableTutorial: false,
            ),
          ),
        ),
      );
      return;
    }

    await CustomDialog(
      width: 860,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: CreateSondageWeb(initialPrefill: prefill),
    ).show<void>(context);
  }
}
