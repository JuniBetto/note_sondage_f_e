import 'package:dio/dio.dart';
import 'package:note_sondage/core/network/setup_dio.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_conversation_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_direct_conversation_summary_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_message_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_team_conversation_summary_entity.dart';
import 'package:note_sondage/feature/chat/infrastructure/data/chat_mapper.dart';

class ChatRemoteDataSource {
  ChatRemoteDataSource();

  final Dio _dio = DioClient().dio;

  Future<ChatConversationEntity> getOrCreateTeamConversation(
    String teamId,
  ) async {
    final response = await _dio.get('/api/chat/teams/$teamId/conversation');
    return ChatMapper.conversationFromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<ChatTeamConversationSummaryEntity> getTeamConversationSummary(
    String teamId,
  ) async {
    final response = await _dio.get('/api/chat/teams/$teamId/summary');
    return ChatMapper.summaryFromJson(response.data as Map<String, dynamic>);
  }

  Future<ChatConversationEntity> getOrCreateDirectConversation(
    String teamId,
    String memberUserId,
  ) async {
    final response = await _dio.get(
      '/api/chat/teams/$teamId/members/$memberUserId/conversation',
    );
    return ChatMapper.conversationFromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<ChatDirectConversationSummaryEntity> getDirectConversationSummary(
    String teamId,
    String memberUserId,
  ) async {
    final response = await _dio.get(
      '/api/chat/teams/$teamId/members/$memberUserId/summary',
    );
    return ChatMapper.directSummaryFromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<List<ChatMessageEntity>> getMessages(
    String conversationId, {
    DateTime? before,
    int limit = 50,
  }) async {
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
  }

  Future<ChatMessageEntity> sendMessage(
    String conversationId,
    String content, {
    String? replyToMessageId,
  }) async {
    final response = await _dio.post(
      '/api/chat/conversations/$conversationId/messages',
      data: {
        'content': content,
        if (replyToMessageId != null && replyToMessageId.trim().isNotEmpty)
          'replyToMessageId': replyToMessageId.trim(),
      },
    );
    return ChatMapper.messageFromJson(response.data as Map<String, dynamic>);
  }

  Future<ChatMessageEntity> sendAttachmentMessage(
    String conversationId, {
    String? content,
    required List<int> bytes,
    required String fileName,
    required String contentType,
    String? replyToMessageId,
  }) async {
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
  }

  Future<void> markConversationRead(String conversationId) async {
    await _dio.post('/api/chat/conversations/$conversationId/read');
  }

  Future<ChatMessageEntity> toggleReaction(
    String messageId,
    String emoji,
  ) async {
    final response = await _dio.post(
      '/api/chat/messages/$messageId/reactions',
      data: {'emoji': emoji},
    );
    return ChatMapper.messageFromJson(response.data as Map<String, dynamic>);
  }

  Future<ChatMessageEntity> deleteMessage(String messageId) async {
    final response = await _dio.delete('/api/chat/messages/$messageId');
    return ChatMapper.messageFromJson(response.data as Map<String, dynamic>);
  }
}
