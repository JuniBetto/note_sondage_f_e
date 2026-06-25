import 'package:note_sondage/feature/chat/domain/entities/chat_conversation_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_direct_conversation_summary_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_message_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_team_conversation_summary_entity.dart';
import 'package:note_sondage/feature/chat/domain/repositories/chat_repository.dart';
import 'package:note_sondage/feature/chat/infrastructure/data_source/chat_local_data_source.dart';
import 'package:note_sondage/feature/chat/infrastructure/data_source/chat_remote_data_source.dart';

class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl(this.local, this.remote);

  final ChatLocalDataSource local;
  final ChatRemoteDataSource remote;

  @override
  ChatConversationEntity? getCachedTeamConversation(String teamId) {
    return local.getConversationByTeamId(teamId);
  }

  @override
  ChatConversationEntity? getCachedDirectConversation(
    String teamId,
    String memberUserId,
  ) {
    return local.getDirectConversation(teamId, memberUserId);
  }

  @override
  List<ChatMessageEntity> getCachedMessages(String conversationId) {
    return local.getMessages(conversationId);
  }

  @override
  ChatTeamConversationSummaryEntity? getCachedTeamSummary(String teamId) {
    return local.getTeamSummary(teamId);
  }

  @override
  ChatDirectConversationSummaryEntity? getCachedDirectSummary(
    String teamId,
    String memberUserId,
  ) {
    return local.getDirectSummary(teamId, memberUserId);
  }

  @override
  Future<ChatConversationEntity> getOrCreateTeamConversation(
    String teamId,
  ) async {
    final conversation = await remote.getOrCreateTeamConversation(teamId);
    await local.saveConversation(conversation);
    return conversation;
  }

  @override
  Future<ChatConversationEntity> getOrCreateDirectConversation(
    String teamId,
    String memberUserId,
  ) async {
    final conversation = await remote.getOrCreateDirectConversation(
      teamId,
      memberUserId,
    );
    await local.saveConversation(conversation);
    return conversation;
  }

  @override
  Future<ChatTeamConversationSummaryEntity> getTeamConversationSummary(
    String teamId,
  ) async {
    final summary = await remote.getTeamConversationSummary(teamId);
    await local.saveSummary(summary);
    return summary;
  }

  @override
  Future<ChatDirectConversationSummaryEntity> getDirectConversationSummary(
    String teamId,
    String memberUserId,
  ) async {
    final summary = await remote.getDirectConversationSummary(
      teamId,
      memberUserId,
    );
    await local.saveDirectSummary(summary);
    return summary;
  }

  @override
  Future<List<ChatMessageEntity>> getMessages(
    String conversationId, {
    DateTime? before,
    int limit = 50,
  }) async {
    final messages = await remote.getMessages(
      conversationId,
      before: before,
      limit: limit,
    );
    if (before == null) {
      await local.saveMessages(conversationId, messages);
    }
    return messages;
  }

  @override
  Future<ChatMessageEntity> sendMessage(
    String conversationId,
    String content, {
    String? replyToMessageId,
  }) async {
    final message = await remote.sendMessage(
      conversationId,
      content,
      replyToMessageId: replyToMessageId,
    );
    await local.upsertMessage(conversationId, message);
    return message;
  }

  @override
  Future<ChatMessageEntity> sendAttachmentMessage(
    String conversationId, {
    String? content,
    required List<int> bytes,
    required String fileName,
    required String contentType,
    String? replyToMessageId,
  }) async {
    final message = await remote.sendAttachmentMessage(
      conversationId,
      content: content,
      bytes: bytes,
      fileName: fileName,
      contentType: contentType,
      replyToMessageId: replyToMessageId,
    );
    await local.upsertMessage(conversationId, message);
    return message;
  }

  @override
  Future<ChatMessageEntity> toggleReaction(
    String messageId,
    String emoji,
  ) async {
    final message = await remote.toggleReaction(messageId, emoji);
    await local.upsertMessage(message.conversationId, message);
    return message;
  }

  @override
  Future<ChatMessageEntity> deleteMessage(String messageId) async {
    final message = await remote.deleteMessage(messageId);
    await local.upsertMessage(message.conversationId, message);
    return message;
  }

  @override
  Future<void> markConversationRead(String conversationId) {
    return remote.markConversationRead(conversationId);
  }
}
