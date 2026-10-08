import 'package:dio/dio.dart';
import 'package:note_sondage/core/network/setup_dio.dart';
import 'package:note_sondage/feature/assistant/domain/entities/assistant_reply_entity.dart';

/// Il server non e' disponibile o l'assistente e' spento (`assistant.enabled=false`).
class AssistantUnavailableException implements Exception {
  const AssistantUnavailableException();
}

class AssistantRemoteDataSource {
  AssistantRemoteDataSource({Dio? dio}) : _dio = dio ?? DioClient().dio;

  static const String _basePath = '/api/aggregate/assistant';

  // Il modello puo' fare piu' giri di strumenti prima di rispondere: il
  // timeout di default (30s) non basta.
  static const Duration _replyTimeout = Duration(seconds: 120);

  final Dio _dio;

  Future<AssistantReplyEntity> sendMessage({
    required String message,
    String? conversationId,
  }) async {
    try {
      final response = await _dio.post(
        '$_basePath/chat',
        data: {
          if (conversationId != null) 'conversationId': conversationId,
          'message': message,
        },
        options: Options(receiveTimeout: _replyTimeout),
      );
      final json = Map<String, dynamic>.from(response.data as Map);
      final tools = (json['executedTools'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .where((tool) => tool['ok'] == true)
          .map((tool) => tool['name'].toString())
          .toList(growable: false);
      return AssistantReplyEntity(
        conversationId: json['conversationId'].toString(),
        reply: (json['reply'] ?? '').toString(),
        executedTools: tools,
      );
    } on DioException catch (error) {
      if (error.response?.statusCode == 503) {
        throw const AssistantUnavailableException();
      }
      rethrow;
    }
  }

  Future<void> deleteConversation(String conversationId) async {
    await _dio.delete('$_basePath/conversations/$conversationId');
  }
}
