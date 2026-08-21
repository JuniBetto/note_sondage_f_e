import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:note_sondage/core/network/setup_dio.dart';
import 'package:note_sondage/feature/event/domain/entities/event_workflow_metadata_entity.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_assignment_create_request_entity.dart';
import 'package:note_sondage/feature/sondage/ui/widgets/sondage_create_prefill.dart';
import 'package:note_sondage/feature/task/domain/entities/task_create_request_entity.dart';
import 'package:note_sondage/feature/task/domain/entities/task_priority.dart';
import 'package:note_sondage/feature/task/domain/entities/task_workflow_metadata_entity.dart';

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

class ChatMessageActionDraftService {
  ChatMessageActionDraftService({Dio? dio}) : _dio = dio ?? DioClient().dio;

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
    return ChatMessageActionDraftResult.fromJson(data);
  }
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

  factory ChatMessageActionDraftResult.fromJson(Map<String, dynamic> json) {
    final rawDraft = json['draft'];
    final draft = rawDraft is Map<String, dynamic>
        ? rawDraft
        : <String, dynamic>{};
    final actionType = json['messageActionType']?.toString().trim() ?? '';
    final source = json['source'] is Map<String, dynamic>
        ? json['source'] as Map<String, dynamic>
        : <String, dynamic>{};
    final workflowMetadata = json['workflowMetadata'] is Map<String, dynamic>
        ? json['workflowMetadata'] as Map<String, dynamic>
        : <String, dynamic>{};

    return ChatMessageActionDraftResult(
      messageActionType: actionType,
      resolutionStatus: json['resolutionStatus']?.toString().trim() ?? '',
      targetEntityType: json['targetEntityType']?.toString().trim() ?? '',
      warnings: (json['warnings'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(ChatMessageActionWarning.fromJson)
          .toList(growable: false),
      fallback: json['fallback'] is Map<String, dynamic>
          ? ChatMessageActionFallback.fromJson(
              json['fallback'] as Map<String, dynamic>,
            )
          : null,
      sondagePrefill: actionType == 'create_sondage'
          ? _parseSondagePrefill(
              draft,
              source: source,
              workflowMetadata: workflowMetadata,
            )
          : null,
      shiftDraft: actionType == 'create_shift'
          ? _parseShiftDraft(
              draft,
              source: source,
              workflowMetadata: workflowMetadata,
            )
          : null,
      taskDraft: actionType == 'create_task'
          ? _parseTaskDraft(
              draft,
              source: source,
              workflowMetadata: workflowMetadata,
            )
          : null,
      eventDraft: actionType == 'create_event'
          ? _parseEventDraft(
              draft,
              source: source,
              workflowMetadata: workflowMetadata,
            )
          : null,
    );
  }

  static SondageCreatePrefill? _parseSondagePrefill(
    Map<String, dynamic> json, {
    required Map<String, dynamic> source,
    required Map<String, dynamic> workflowMetadata,
  }) {
    final question = json['question']?.toString().trim() ?? '';
    final options = (json['options'] as List<dynamic>? ?? const <dynamic>[])
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    if (question.isEmpty || options.isEmpty) {
      return null;
    }
    return SondageCreatePrefill(
      question: question,
      description: json['description']?.toString().trim(),
      teamId: json['teamId']?.toString().trim(),
      options: options,
      allowMultipleResponses: json['allowMultipleResponses'] == true,
      expiryDate: DateTime.tryParse(json['expiryDate']?.toString() ?? ''),
      contextType: _trimOrNull(workflowMetadata['contextType']),
      contextId: _trimOrNull(workflowMetadata['contextId']),
      sourceType:
          _trimOrNull(source['sourceType']) ??
          _trimOrNull(workflowMetadata['sourceType']),
      sourceId:
          _trimOrNull(workflowMetadata['sourceId']) ??
          _trimOrNull(source['conversationId']),
      sourceMessageId:
          _trimOrNull(workflowMetadata['sourceMessageId']) ??
          _trimOrNull(source['sourceMessageId']) ??
          _trimOrNull(source['messageId']),
    );
  }

  static ShiftAssignmentCreateRequestEntity? _parseShiftDraft(
    Map<String, dynamic> json, {
    required Map<String, dynamic> source,
    required Map<String, dynamic> workflowMetadata,
  }) {
    final shiftDate = DateTime.tryParse(json['shiftDate']?.toString() ?? '');
    if (shiftDate == null) {
      return null;
    }
    return ShiftAssignmentCreateRequestEntity(
      shiftDate: shiftDate,
      profileId: _trimOrNull(json['profileId']),
      startTime: _parseTimeOfDay(json['startTime']),
      endTime: _parseTimeOfDay(json['endTime']),
      overnight: json['overnight'] as bool?,
      note: _trimOrNull(json['note']),
      alarmOffsets: (json['alarmOffsets'] as List<dynamic>?)
          ?.map((item) => int.tryParse(item.toString()))
          .whereType<int>()
          .toList(growable: false),
      isPublic: json['isPublic'] == true,
      teamId: _trimOrNull(json['teamId']),
      teamShiftGroupId: _trimOrNull(json['teamShiftGroupId']),
      targetUserId: _trimOrNull(json['targetUserId']),
      targetUserName: _trimOrNull(json['targetUserName']),
      contextType: _trimOrNull(workflowMetadata['contextType']),
      contextId: _trimOrNull(workflowMetadata['contextId']),
      sourceType:
          _trimOrNull(source['sourceType']) ??
          _trimOrNull(workflowMetadata['sourceType']),
      sourceId:
          _trimOrNull(workflowMetadata['sourceId']) ??
          _trimOrNull(source['conversationId']),
      sourceMessageId:
          _trimOrNull(workflowMetadata['sourceMessageId']) ??
          _trimOrNull(source['sourceMessageId']) ??
          _trimOrNull(source['messageId']),
    );
  }

  static TaskCreateRequestEntity? _parseTaskDraft(
    Map<String, dynamic> json, {
    required Map<String, dynamic> source,
    required Map<String, dynamic> workflowMetadata,
  }) {
    final title = json['title']?.toString().trim() ?? '';
    final teamId = _trimOrNull(json['teamId']);
    if (title.isEmpty || teamId == null) {
      return null;
    }
    return TaskCreateRequestEntity(
      teamId: teamId,
      title: title,
      description: _trimOrNull(json['description']),
      priority: TaskPriorityWireValue.fromWireValue(
        json['priority']?.toString(),
      ),
      dueAt: DateTime.tryParse(json['dueAt']?.toString() ?? ''),
      assigneeUserId: _trimOrNull(json['assigneeUserId']),
      assigneeDisplayName: _trimOrNull(json['assigneeDisplayName']),
      workflowMetadata: TaskWorkflowMetadataEntity(
        contextType: _trimOrNull(workflowMetadata['contextType']),
        contextId: _trimOrNull(workflowMetadata['contextId']),
        sourceType:
            _trimOrNull(source['sourceType']) ??
            _trimOrNull(workflowMetadata['sourceType']),
        sourceId:
            _trimOrNull(workflowMetadata['sourceId']) ??
            _trimOrNull(source['conversationId']),
        sourceMessageId:
            _trimOrNull(workflowMetadata['sourceMessageId']) ??
            _trimOrNull(source['sourceMessageId']) ??
            _trimOrNull(source['messageId']),
      ),
    );
  }

  static ChatMessageActionEventDraft? _parseEventDraft(
    Map<String, dynamic> json, {
    required Map<String, dynamic> source,
    required Map<String, dynamic> workflowMetadata,
  }) {
    final title = json['title']?.toString().trim() ?? '';
    final startsAt = DateTime.tryParse(json['startsAt']?.toString() ?? '');
    if (title.isEmpty || startsAt == null) {
      return null;
    }
    return ChatMessageActionEventDraft(
      teamId: _trimOrNull(json['teamId']),
      title: title,
      description: _trimOrNull(json['description']),
      startsAt: startsAt,
      endsAt: DateTime.tryParse(json['endsAt']?.toString() ?? ''),
      allDay: json['allDay'] == true,
      location: _trimOrNull(json['location']),
      participantUserIds:
          (json['participantUserIds'] as List<dynamic>?)
              ?.map((item) => item.toString().trim())
              .where((item) => item.isNotEmpty)
              .toList(growable: false) ??
          const <String>[],
      participantDisplayNames:
          (json['participantDisplayNames'] as List<dynamic>?)
              ?.map((item) => item.toString().trim())
              .where((item) => item.isNotEmpty)
              .toList(growable: false) ??
          const <String>[],
      workflowMetadata: EventWorkflowMetadataEntity(
        contextType: _trimOrNull(workflowMetadata['contextType']),
        contextId: _trimOrNull(workflowMetadata['contextId']),
        sourceType:
            _trimOrNull(source['sourceType']) ??
            _trimOrNull(workflowMetadata['sourceType']),
        sourceId:
            _trimOrNull(workflowMetadata['sourceId']) ??
            _trimOrNull(source['conversationId']),
        sourceMessageId:
            _trimOrNull(workflowMetadata['sourceMessageId']) ??
            _trimOrNull(source['sourceMessageId']) ??
            _trimOrNull(source['messageId']),
      ),
    );
  }

  static TimeOfDay? _parseTimeOfDay(Object? raw) {
    final value = raw?.toString().trim() ?? '';
    if (value.isEmpty) {
      return null;
    }
    final parts = value.split(':');
    if (parts.length < 2) {
      return null;
    }
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) {
      return null;
    }
    return TimeOfDay(hour: hour, minute: minute);
  }

  static String? _trimOrNull(Object? raw) {
    final value = raw?.toString().trim() ?? '';
    return value.isEmpty ? null : value;
  }
}

class ChatMessageActionWarning {
  const ChatMessageActionWarning({required this.code, required this.message});

  final String code;
  final String message;

  factory ChatMessageActionWarning.fromJson(Map<String, dynamic> json) {
    return ChatMessageActionWarning(
      code: json['code']?.toString().trim() ?? '',
      message: json['message']?.toString().trim() ?? '',
    );
  }
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

  factory ChatMessageActionFallback.fromJson(Map<String, dynamic> json) {
    return ChatMessageActionFallback(
      type: json['type']?.toString().trim() ?? '',
      reasonCode: json['reasonCode']?.toString().trim() ?? '',
      message: json['message']?.toString().trim() ?? '',
    );
  }
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
