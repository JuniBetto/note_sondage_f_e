import 'package:note_sondage/feature/chat/domain/entities/chat_conversation_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_direct_conversation_summary_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_message_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_team_conversation_summary_entity.dart';
import 'package:note_sondage/feature/chat/domain/repositories/chat_repository.dart';

class ChatUseCase {
  ChatUseCase(this.repository);

  final ChatRepository repository;

  ChatConversationEntity? getCachedTeamConversation(String teamId) {
    return repository.getCachedTeamConversation(teamId);
  }

  ChatConversationEntity? getCachedDirectConversation(
    String teamId,
    String memberUserId,
  ) {
    return repository.getCachedDirectConversation(teamId, memberUserId);
  }

  List<ChatMessageEntity> getCachedMessages(String conversationId) {
    return repository.getCachedMessages(conversationId);
  }

  ChatTeamConversationSummaryEntity? getCachedTeamSummary(String teamId) {
    return repository.getCachedTeamSummary(teamId);
  }

  ChatDirectConversationSummaryEntity? getCachedDirectSummary(
    String teamId,
    String memberUserId,
  ) {
    return repository.getCachedDirectSummary(teamId, memberUserId);
  }

  Future<ChatConversationEntity> getOrCreateTeamConversation(String teamId) {
    return repository.getOrCreateTeamConversation(teamId);
  }

  Future<ChatConversationEntity> getOrCreateDirectConversation(
    String teamId,
    String memberUserId,
  ) {
    return repository.getOrCreateDirectConversation(teamId, memberUserId);
  }

  Future<ChatTeamConversationSummaryEntity> getTeamConversationSummary(
    String teamId,
  ) {
    return repository.getTeamConversationSummary(teamId);
  }

  Future<ChatDirectConversationSummaryEntity> getDirectConversationSummary(
    String teamId,
    String memberUserId,
  ) {
    return repository.getDirectConversationSummary(teamId, memberUserId);
  }

  Future<List<ChatMessageEntity>> getMessages(
    String conversationId, {
    DateTime? before,
    int limit = 50,
  }) {
    return repository.getMessages(conversationId, before: before, limit: limit);
  }

  Future<ChatMessageEntity> sendMessage(
    String conversationId,
    String content, {
    String? replyToMessageId,
  }) {
    return repository.sendMessage(
      conversationId,
      content,
      replyToMessageId: replyToMessageId,
    );
  }

  Future<ChatMessageEntity> sendAttachmentMessage(
    String conversationId, {
    String? content,
    required List<int> bytes,
    required String fileName,
    required String contentType,
    String? replyToMessageId,
  }) {
    return repository.sendAttachmentMessage(
      conversationId,
      content: content,
      bytes: bytes,
      fileName: fileName,
      contentType: contentType,
      replyToMessageId: replyToMessageId,
    );
  }

  Future<ChatMessageEntity> toggleReaction(String messageId, String emoji) {
    return repository.toggleReaction(messageId, emoji);
  }

  Future<ChatMessageEntity> deleteMessage(String messageId) {
    return repository.deleteMessage(messageId);
  }

  Future<void> markConversationRead(String conversationId) {
    return repository.markConversationRead(conversationId);
  }
}
