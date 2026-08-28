import 'package:note_sondage/feature/chat/domain/entities/chat_message_action_entity.dart';

abstract class ChatMessageActionRepository {
  Future<ChatMessageActionDraftResult> buildDraft({
    required ChatMessageActionType actionType,
    required String conversationId,
    required String messageId,
    required String teamId,
    required String locale,
    String? selectedMessageText,
    String? memberUserId,
    String? memberDisplayName,
  });
}
