import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:note_sondage/feature/chat/domain/entities/blocked_user_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_conversation_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_direct_conversation_summary_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_message_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_message_report_reason.dart';
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
    final scope = local.cacheScope;
    final conversation = await remote.getOrCreateTeamConversation(teamId);
    _cacheInBackground(scope, () => local.saveConversation(conversation));
    return conversation;
  }

  @override
  Future<ChatConversationEntity> getOrCreateDirectConversation(
    String teamId,
    String memberUserId,
  ) async {
    final scope = local.cacheScope;
    final conversation = _requireMatchingDirectConversation(
      await remote.getOrCreateDirectConversation(teamId, memberUserId),
      memberUserId,
    );
    _cacheInBackground(scope, () => local.saveConversation(conversation));
    return conversation;
  }

  @override
  Future<ChatTeamConversationSummaryEntity> getTeamConversationSummary(
    String teamId,
  ) async {
    final scope = local.cacheScope;
    final summary = await remote.getTeamConversationSummary(teamId);
    _cacheInBackground(scope, () => local.saveSummary(summary));
    return summary;
  }

  @override
  Future<ChatDirectConversationSummaryEntity> getDirectConversationSummary(
    String teamId,
    String memberUserId,
  ) async {
    final scope = local.cacheScope;
    final summary = _requireMatchingDirectSummary(
      await remote.getDirectConversationSummary(teamId, memberUserId),
      memberUserId,
    );
    _cacheInBackground(scope, () => local.saveDirectSummary(summary));
    return summary;
  }

  @override
  Future<List<ChatMessageEntity>> getMessages(
    String conversationId, {
    DateTime? before,
    int limit = 50,
  }) async {
    final scope = local.cacheScope;
    final messages = await remote.getMessages(
      conversationId,
      before: before,
      limit: limit,
    );
    if (before == null) {
      _cacheInBackground(
        scope,
        () => local.saveMessages(conversationId, messages),
      );
    }
    return messages;
  }

  @override
  Future<ChatMessageEntity> sendMessage(
    String conversationId,
    String content, {
    String? replyToMessageId,
  }) async {
    final scope = local.cacheScope;
    final message = await remote.sendMessage(
      conversationId,
      content,
      replyToMessageId: replyToMessageId,
    );
    _cacheInBackground(
      scope,
      () => local.upsertMessage(conversationId, message),
    );
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
    final scope = local.cacheScope;
    final message = await remote.sendAttachmentMessage(
      conversationId,
      content: content,
      bytes: bytes,
      fileName: fileName,
      contentType: contentType,
      replyToMessageId: replyToMessageId,
    );
    _cacheInBackground(
      scope,
      () => local.upsertMessage(conversationId, message),
    );
    return message;
  }

  @override
  Future<ChatMessageEntity> toggleReaction(
    String messageId,
    String emoji,
  ) async {
    final scope = local.cacheScope;
    final message = await remote.toggleReaction(messageId, emoji);
    _cacheInBackground(
      scope,
      () => local.upsertMessage(message.conversationId, message),
    );
    return message;
  }

  @override
  Future<ChatMessageEntity> deleteMessage(String messageId) async {
    final scope = local.cacheScope;
    final message = await remote.deleteMessage(messageId);
    _cacheInBackground(
      scope,
      () => local.upsertMessage(message.conversationId, message),
    );
    return message;
  }

  @override
  Future<void> markConversationRead(String conversationId) {
    return remote.markConversationRead(conversationId);
  }

  @override
  Future<BlockedUserEntity> blockSender(String messageId) {
    return remote.blockSender(messageId);
  }

  @override
  Future<void> unblockUser(String blockedUserId) {
    return remote.unblockUser(blockedUserId);
  }

  @override
  Future<List<BlockedUserEntity>> getBlockedUsers() {
    return remote.getBlockedUsers();
  }

  @override
  Future<void> reportMessage(
    String messageId, {
    required ChatMessageReportReason reason,
    String? comment,
  }) {
    return remote.reportMessage(messageId, reason: reason, comment: comment);
  }

  void _cacheInBackground(String scope, Future<void> Function() write) {
    // A response started by another account must never enter the current cache.
    if (local.cacheScope != scope) {
      return;
    }
    try {
      // The datasource updates memory synchronously before its first await.
      unawaited(
        write().then<void>(
          (_) {},
          onError: (Object error, StackTrace stackTrace) {
            debugPrint('Chat cache write failed: ${error.runtimeType}');
          },
        ),
      );
    } catch (error) {
      // Cache failure must not turn a successful server send into a retry/duplicate.
      debugPrint('Chat cache write failed: ${error.runtimeType}');
    }
  }

  ChatConversationEntity _requireMatchingDirectConversation(
    ChatConversationEntity conversation,
    String requestedMemberUserId,
  ) {
    final participantUserId = conversation.participantUserId?.trim() ?? '';
    final normalizedRequestedMemberUserId = requestedMemberUserId.trim();
    if (participantUserId.isEmpty ||
        participantUserId != normalizedRequestedMemberUserId) {
      throw StateError(
        'Direct conversation participant mismatch for '
        '$normalizedRequestedMemberUserId',
      );
    }
    return conversation;
  }

  ChatDirectConversationSummaryEntity _requireMatchingDirectSummary(
    ChatDirectConversationSummaryEntity summary,
    String requestedMemberUserId,
  ) {
    final normalizedRequestedMemberUserId = requestedMemberUserId.trim();
    if (summary.participantUserId.trim() != normalizedRequestedMemberUserId) {
      throw StateError(
        'Direct summary participant mismatch for '
        '$normalizedRequestedMemberUserId',
      );
    }
    return summary;
  }
}
