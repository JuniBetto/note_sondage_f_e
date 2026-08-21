import 'package:dio/dio.dart';
import 'package:note_sondage/core/network/setup_dio.dart';
import 'package:note_sondage/feature/chat/workflow/chat_message_action_draft_service.dart';
import 'package:note_sondage/feature/chat/workflow/chat_message_suggestion_models.dart';

class ChatMessageSuggestionService {
  ChatMessageSuggestionService({Dio? dio}) : _dio = dio ?? DioClient().dio;

  final Dio _dio;

  Future<DetectWorkflowSuggestionResult> detectWorkflowSuggestionFromMessage({
    required String conversationId,
    required String messageId,
    required String teamId,
    required String locale,
    List<ChatMessageActionType> allowedActionTypes =
        const <ChatMessageActionType>[
          ChatMessageActionType.createTask,
          ChatMessageActionType.createEvent,
          ChatMessageActionType.createSondage,
        ],
    String? selectedMessageText,
    String? memberUserId,
    String? memberDisplayName,
    String? replyToMessageId,
    int maxSuggestions = 3,
  }) async {
    final response = await _dio.post(
      '/api/aggregate/workflow/message-suggestions/detect',
      data: {
        'conversationId': conversationId,
        'messageId': messageId,
        'teamId': teamId,
        if (selectedMessageText != null &&
            selectedMessageText.trim().isNotEmpty)
          'selectedMessageText': selectedMessageText.trim(),
        if (replyToMessageId != null && replyToMessageId.trim().isNotEmpty)
          'replyToMessageId': replyToMessageId.trim(),
        'allowedActionTypes': allowedActionTypes
            .map((actionType) => actionType.wireValue)
            .toList(growable: false),
        'maxSuggestions': maxSuggestions,
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
      throw Exception('Invalid workflow suggestion response');
    }
    return DetectWorkflowSuggestionResult.fromJson(data);
  }
}
