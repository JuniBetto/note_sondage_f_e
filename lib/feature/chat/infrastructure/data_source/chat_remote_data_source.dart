import 'package:dio/dio.dart';
import 'package:note_sondage/core/network/setup_dio.dart';
import 'package:note_sondage/feature/chat/domain/entities/blocked_user_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_conversation_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_direct_conversation_summary_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_message_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_message_report_reason.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_team_conversation_summary_entity.dart';
import 'package:note_sondage/feature/chat/infrastructure/data/chat_mapper.dart';

class ChatRemoteDataSource {
  ChatRemoteDataSource({Dio? dio}) : _dio = dio ?? DioClient().dio;

  final Dio _dio;

  Future<ChatConversationEntity> getOrCreateTeamConversation(
    String teamId,
  ) async {
    try {
      final response = await _dio.get('/api/chat/teams/$teamId/conversation');
      return ChatMapper.conversationFromJson(
        response.data as Map<String, dynamic>,
      );
    } catch (e) {
      throw Exception('Failed to fetch team conversation: $e');
    }
  }

  Future<ChatTeamConversationSummaryEntity> getTeamConversationSummary(
    String teamId,
  ) async {
    try {
      final response = await _dio.get('/api/chat/teams/$teamId/summary');
      return ChatMapper.summaryFromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to fetch team conversation summary: $e');
    }
  }

  Future<ChatConversationEntity> getOrCreateDirectConversation(
    String teamId,
    String memberUserId,
  ) async {
    try {
      final response = await _dio.get(
        '/api/chat/teams/$teamId/members/$memberUserId/conversation',
      );
      return ChatMapper.conversationFromJson(
        response.data as Map<String, dynamic>,
      );
    } catch (e) {
      throw Exception('Failed to fetch direct conversation: $e');
    }
  }

  Future<ChatDirectConversationSummaryEntity> getDirectConversationSummary(
    String teamId,
    String memberUserId,
  ) async {
    try {
      final response = await _dio.get(
        '/api/chat/teams/$teamId/members/$memberUserId/summary',
      );
      return ChatMapper.directSummaryFromJson(
        response.data as Map<String, dynamic>,
      );
    } catch (e) {
      throw Exception('Failed to fetch direct conversation summary: $e');
    }
  }

  Future<List<ChatMessageEntity>> getMessages(
    String conversationId, {
    DateTime? before,
    int limit = 50,
  }) async {
    try {
      final response = await _dio.get(
        '/api/chat/conversations/$conversationId/messages',
        queryParameters: {
          'limit': limit,
          if (before != null) 'before': before.toIso8601String(),
        },
      );
      final data = response.data as List<dynamic>? ?? const <dynamic>[];
      return data
          .whereType<Map<String, dynamic>>()
          .map(ChatMapper.messageFromJson)
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch messages: $e');
    }
  }

  Future<ChatMessageEntity> sendMessage(
    String conversationId,
    String content, {
    String? replyToMessageId,
  }) async {
    try {
      final response = await _dio.post(
        '/api/chat/conversations/$conversationId/messages',
        data: {
          'content': content,
          if (replyToMessageId != null && replyToMessageId.trim().isNotEmpty)
            'replyToMessageId': replyToMessageId.trim(),
        },
      );
      return ChatMapper.messageFromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  Future<ChatMessageEntity> sendAttachmentMessage(
    String conversationId, {
    String? content,
    required List<int> bytes,
    required String fileName,
    required String contentType,
    String? replyToMessageId,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: fileName),
        if (content != null && content.trim().isNotEmpty)
          'content': content.trim(),
        if (replyToMessageId != null && replyToMessageId.trim().isNotEmpty)
          'replyToMessageId': replyToMessageId.trim(),
      });
      final response = await _dio.post(
        '/api/chat/conversations/$conversationId/messages',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return ChatMapper.messageFromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to send attachment message: $e');
    }
  }

  Future<void> markConversationRead(String conversationId) async {
    try {
      await _dio.post('/api/chat/conversations/$conversationId/read');
    } catch (e) {
      throw Exception('Failed to mark conversation as read: $e');
    }
  }

  Future<ChatMessageEntity> toggleReaction(
    String messageId,
    String emoji,
  ) async {
    try {
      final response = await _dio.post(
        '/api/chat/messages/$messageId/reactions',
        data: {'emoji': emoji},
      );
      return ChatMapper.messageFromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to toggle reaction: $e');
    }
  }

  Future<ChatMessageEntity> deleteMessage(String messageId) async {
    try {
      final response = await _dio.delete('/api/chat/messages/$messageId');
      return ChatMapper.messageFromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }

  Future<BlockedUserEntity> blockSender(String messageId) async {
    try {
      final response = await _dio.post(
        '/api/chat/messages/$messageId/block-sender',
      );
      return ChatMapper.blockedUserFromJson(
        response.data as Map<String, dynamic>,
      );
    } catch (e) {
      throw Exception('Failed to block sender: $e');
    }
  }

  Future<void> unblockUser(String blockedUserId) async {
    try {
      await _dio.delete('/api/chat/blocked-users/$blockedUserId');
    } catch (e) {
      throw Exception('Failed to unblock user: $e');
    }
  }

  Future<List<BlockedUserEntity>> getBlockedUsers() async {
    try {
      final response = await _dio.get('/api/chat/blocked-users');
      final data = response.data as List<dynamic>? ?? const <dynamic>[];
      return data
          .whereType<Map<String, dynamic>>()
          .map(ChatMapper.blockedUserFromJson)
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch blocked users: $e');
    }
  }

  Future<void> reportMessage(
    String messageId, {
    required ChatMessageReportReason reason,
    String? comment,
  }) async {
    try {
      await _dio.post(
        '/api/chat/messages/$messageId/report',
        data: {
          'reason': reason.wireValue,
          if (comment != null && comment.trim().isNotEmpty)
            'comment': comment.trim(),
        },
      );
    } catch (e) {
      throw Exception('Failed to report message: $e');
    }
  }
}
