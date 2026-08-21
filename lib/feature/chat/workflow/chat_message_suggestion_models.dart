import 'package:note_sondage/feature/chat/workflow/chat_message_action_draft_service.dart';

class DetectWorkflowSuggestionResult {
  const DetectWorkflowSuggestionResult({
    required this.resolutionStatus,
    required this.suggestions,
    required this.warnings,
    this.fallback,
    this.workflowMetadata = const <String, String>{},
  });

  final String resolutionStatus;
  final List<WorkflowSuggestionItem> suggestions;
  final List<ChatMessageActionWarning> warnings;
  final ChatMessageActionFallback? fallback;
  final Map<String, String> workflowMetadata;

  bool get isUnsupported =>
      resolutionStatus.trim().toLowerCase() == 'unsupported';

  factory DetectWorkflowSuggestionResult.fromJson(Map<String, dynamic> json) {
    return DetectWorkflowSuggestionResult(
      resolutionStatus: json['resolutionStatus']?.toString().trim() ?? '',
      suggestions: (json['suggestions'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(WorkflowSuggestionItem.fromJson)
          .toList(growable: false),
      warnings: (json['warnings'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(ChatMessageActionWarning.fromJson)
          .toList(growable: false),
      fallback: json['fallback'] is Map<String, dynamic>
          ? ChatMessageActionFallback.fromJson(
              json['fallback'] as Map<String, dynamic>,
            )
          : null,
      workflowMetadata:
          (json['workflowMetadata'] as Map<String, dynamic>? ??
                  const <String, dynamic>{})
              .map(
                (key, value) =>
                    MapEntry(key.toString(), value?.toString().trim() ?? ''),
              ),
    );
  }
}

class WorkflowSuggestionItem {
  const WorkflowSuggestionItem({
    required this.suggestionId,
    required this.actionType,
    required this.targetEntityType,
    required this.confidence,
    required this.title,
    required this.reason,
    this.missingFields = const <String>[],
    this.preview = const <String, dynamic>{},
  });

  final String suggestionId;
  final ChatMessageActionType? actionType;
  final String targetEntityType;
  final String confidence;
  final String title;
  final String reason;
  final List<String> missingFields;
  final Map<String, dynamic> preview;

  factory WorkflowSuggestionItem.fromJson(Map<String, dynamic> json) {
    return WorkflowSuggestionItem(
      suggestionId: json['suggestionId']?.toString().trim() ?? '',
      actionType: ChatMessageActionTypeValueX.fromWireValue(
        json['actionType']?.toString(),
      ),
      targetEntityType: json['targetEntityType']?.toString().trim() ?? '',
      confidence: json['confidence']?.toString().trim() ?? '',
      title: json['title']?.toString().trim() ?? '',
      reason: json['reason']?.toString().trim() ?? '',
      missingFields:
          (json['missingFields'] as List<dynamic>? ?? const <dynamic>[])
              .map((item) => item.toString().trim())
              .where((item) => item.isNotEmpty)
              .toList(growable: false),
      preview: json['preview'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['preview'] as Map<String, dynamic>)
          : const <String, dynamic>{},
    );
  }
}

extension ChatMessageActionTypeValueX on ChatMessageActionType {
  static ChatMessageActionType? fromWireValue(String? value) {
    return switch (value?.trim().toLowerCase()) {
      'create_sondage' => ChatMessageActionType.createSondage,
      'create_shift' => ChatMessageActionType.createShift,
      'create_task' => ChatMessageActionType.createTask,
      'create_event' => ChatMessageActionType.createEvent,
      _ => null,
    };
  }
}
