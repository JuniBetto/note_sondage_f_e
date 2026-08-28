import 'package:note_sondage/feature/chat/domain/entities/chat_message_action_entity.dart';
import 'package:note_sondage/feature/chat/domain/repositories/chat_message_action_repository.dart';
import 'package:note_sondage/feature/chat/infrastructure/data_source/chat_message_action_remote_data_source.dart';

class ChatMessageActionRepositoryImpl implements ChatMessageActionRepository {
  ChatMessageActionRepositoryImpl(this.remote);

  final ChatMessageActionRemoteDataSource remote;

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
    return remote.buildDraft(
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
