import 'package:note_sondage/feature/chat/domain/entities/chat_message_action_entity.dart';
import 'package:note_sondage/feature/chat/domain/repositories/chat_message_action_repository.dart';

class ChatMessageActionUseCase {
  ChatMessageActionUseCase(this.repository);

  final ChatMessageActionRepository repository;

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
    return repository.buildDraft(
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
