import 'package:note_sondage/feature/event/domain/entities/event_workflow_metadata_entity.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_assignment_create_request_entity.dart';
import 'package:note_sondage/feature/sondage/ui/widgets/sondage_create_prefill.dart';
import 'package:note_sondage/feature/task/domain/entities/task_create_request_entity.dart';

enum ChatMessageActionType {
  createSondage,
  createShift,
  createTask,
  createEvent,
}

extension ChatMessageActionTypeValue on ChatMessageActionType {
  String get wireValue => switch (this) {
    ChatMessageActionType.createSondage => 'create_sondage',
    ChatMessageActionType.createShift => 'create_shift',
    ChatMessageActionType.createTask => 'create_task',
    ChatMessageActionType.createEvent => 'create_event',
  };
}

class ChatMessageActionDraftResult {
  const ChatMessageActionDraftResult({
    required this.messageActionType,
    required this.resolutionStatus,
    required this.targetEntityType,
    required this.warnings,
    this.fallback,
    this.sondagePrefill,
    this.shiftDraft,
    this.taskDraft,
    this.eventDraft,
  });

  final String messageActionType;
  final String resolutionStatus;
  final String targetEntityType;
  final List<ChatMessageActionWarning> warnings;
  final ChatMessageActionFallback? fallback;
  final SondageCreatePrefill? sondagePrefill;
  final ShiftAssignmentCreateRequestEntity? shiftDraft;
  final TaskCreateRequestEntity? taskDraft;
  final ChatMessageActionEventDraft? eventDraft;

  bool get isUnsupported =>
      resolutionStatus.trim().toLowerCase() == 'unsupported';

  bool get isPartial => resolutionStatus.trim().toLowerCase() == 'partial';

  String? get primaryMessage {
    final fallbackMessage = fallback?.message.trim();
    if (fallbackMessage != null && fallbackMessage.isNotEmpty) {
      return fallbackMessage;
    }
    for (final warning in warnings) {
      final value = warning.message.trim();
      if (value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }
}

class ChatMessageActionWarning {
  const ChatMessageActionWarning({required this.code, required this.message});

  final String code;
  final String message;
}

class ChatMessageActionFallback {
  const ChatMessageActionFallback({
    required this.type,
    required this.reasonCode,
    required this.message,
  });

  final String type;
  final String reasonCode;
  final String message;
}

class ChatMessageActionEventDraft {
  const ChatMessageActionEventDraft({
    required this.title,
    required this.startsAt,
    required this.workflowMetadata,
    this.teamId,
    this.description,
    this.endsAt,
    this.allDay = false,
    this.location,
    this.participantUserIds = const <String>[],
    this.participantDisplayNames = const <String>[],
  });

  final String? teamId;
  final String title;
  final String? description;
  final DateTime startsAt;
  final DateTime? endsAt;
  final bool allDay;
  final String? location;
  final List<String> participantUserIds;
  final List<String> participantDisplayNames;
  final EventWorkflowMetadataEntity workflowMetadata;
}
