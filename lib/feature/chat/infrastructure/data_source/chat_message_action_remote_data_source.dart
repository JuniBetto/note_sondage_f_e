import 'package:dio/dio.dart';
import 'package:note_sondage/core/network/setup_dio.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_message_action_entity.dart';
import 'package:note_sondage/feature/chat/infrastructure/data/chat_message_action_mapper.dart';

class ChatMessageActionRemoteDataSource {
  ChatMessageActionRemoteDataSource({Dio? dio}) : _dio = dio ?? DioClient().dio;

  final Dio _dio;

  Future<ChatMessageActionDraftResult> buildDraft({
    required ChatMessageActionType actionType,
    required String conversationId,
    required String messageId,
    required String teamId,
    required String locale,
    String? selectedMessageText,
    String? memberUserId,
    String? memberDisplayName,
  }) async {
    final response = await _dio.post(
      '/api/aggregate/workflow/message-actions/draft',
      data: {
        'messageActionType': actionType.wireValue,
        'conversationId': conversationId,
        'messageId': messageId,
        'teamId': teamId,
        if (selectedMessageText != null &&
            selectedMessageText.trim().isNotEmpty)
          'selectedMessageText': selectedMessageText.trim(),
        'clientContext': {
          'chatType': memberUserId == null || memberUserId.trim().isEmpty
              ? 'TEAM'
              : 'DIRECT',
          if (memberUserId != null && memberUserId.trim().isNotEmpty)
            'memberUserId': memberUserId.trim(),
          if (memberDisplayName != null && memberDisplayName.trim().isNotEmpty)
            'memberDisplayName': memberDisplayName.trim(),
          'locale': locale.trim(),
        },
      },
    );

    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid workflow action response');
    }
    return ChatMessageActionMapper.fromJson(data);
  }
}
