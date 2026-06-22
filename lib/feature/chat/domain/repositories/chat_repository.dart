import 'package:note_sondage/feature/chat/domain/entities/chat_conversation_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_direct_conversation_summary_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_message_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_team_conversation_summary_entity.dart';

abstract class ChatRepository {
  ChatConversationEntity? getCachedTeamConversation(String teamId);

  ChatConversationEntity? getCachedDirectConversation(
    String teamId,
    String memberUserId,
  );

  List<ChatMessageEntity> getCachedMessages(String conversationId);

  ChatTeamConversationSummaryEntity? getCachedTeamSummary(String teamId);

  ChatDirectConversationSummaryEntity? getCachedDirectSummary(
    String teamId,
    String memberUserId,
  );

  Future<ChatConversationEntity> getOrCreateTeamConversation(String teamId);

  Future<ChatConversationEntity> getOrCreateDirectConversation(
    String teamId,
    String memberUserId,
  );

  Future<ChatTeamConversationSummaryEntity> getTeamConversationSummary(
    String teamId,
  );

  Future<ChatDirectConversationSummaryEntity> getDirectConversationSummary(
    String teamId,
    String memberUserId,
  );

  Future<List<ChatMessageEntity>> getMessages(
    String conversationId, {
    DateTime? before,
    int limit = 50,
  });

  Future<ChatMessageEntity> sendMessage(
    String conversationId,
    String content, {
    String? replyToMessageId,
  });

  Future<ChatMessageEntity> sendAttachmentMessage(
    String conversationId, {
    String? content,
    required List<int> bytes,
    required String fileName,
    required String contentType,
    String? replyToMessageId,
  });

  Future<ChatMessageEntity> toggleReaction(String messageId, String emoji);

  Future<ChatMessageEntity> deleteMessage(String messageId);

  Future<void> markConversationRead(String conversationId);
}
