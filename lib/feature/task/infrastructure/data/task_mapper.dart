import 'package:note_sondage/feature/task/domain/entities/task_create_request_entity.dart';
import 'package:note_sondage/feature/task/domain/entities/task_entity.dart';
import 'package:note_sondage/feature/task/domain/entities/task_priority.dart';
import 'package:note_sondage/feature/task/domain/entities/task_status.dart';
import 'package:note_sondage/feature/task/domain/entities/task_update_request_entity.dart';
import 'package:note_sondage/feature/task/domain/entities/task_workflow_metadata_entity.dart';

class TaskMapper {
  const TaskMapper._();

  static TaskEntity fromJson(Map<String, dynamic> json) {
    return TaskEntity(
      id: json['id']?.toString().trim() ?? '',
      teamId: json['teamId']?.toString().trim() ?? '',
      title: json['title']?.toString().trim() ?? '',
      description: _trimOrNull(json['description']),
      status: TaskStatusWireValue.fromWireValue(json['status']?.toString()),
      priority: TaskPriorityWireValue.fromWireValue(
        json['priority']?.toString(),
      ),
      dueAt: _parseDateTime(json['dueAt']),
      assigneeUserId: _trimOrNull(json['assigneeUserId']),
      assigneeDisplayName: _trimOrNull(json['assigneeDisplayName']),
      createdByUserId: json['createdByUserId']?.toString().trim() ?? '',
      createdByDisplayName: _trimOrNull(json['createdByDisplayName']),
      workflowMetadata: _workflowMetadataFromJson(json['workflowMetadata']),
      completedAt: _parseDateTime(json['completedAt']),
      archivedAt: _parseDateTime(json['archivedAt']),
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(json['updatedAt']) ?? DateTime.now(),
    );
  }

  static Map<String, dynamic> createRequestToJson(
    TaskCreateRequestEntity request,
  ) {
    return <String, dynamic>{
      'teamId': request.teamId,
      'title': request.title.trim(),
      if (_hasText(request.description))
        'description': request.description!.trim(),
      'priority': request.priority.wireValue,
      if (request.dueAt != null) 'dueAt': request.dueAt!.toIso8601String(),
      if (_hasText(request.assigneeUserId))
        'assigneeUserId': request.assigneeUserId!.trim(),
      if (_hasText(request.assigneeDisplayName))
        'assigneeDisplayName': request.assigneeDisplayName!.trim(),
      if (_hasText(request.createdByUserId))
        'createdByUserId': request.createdByUserId!.trim(),
      if (_hasText(request.createdByDisplayName))
        'createdByDisplayName': request.createdByDisplayName!.trim(),
      if (request.workflowMetadata != null)
        'workflowMetadata': workflowMetadataToJson(request.workflowMetadata!),
    };
  }

  static Map<String, dynamic> updateRequestToJson(
    TaskUpdateRequestEntity request,
  ) {
    return <String, dynamic>{
      if (_hasText(request.title)) 'title': request.title!.trim(),
      if (request.description != null) 'description': request.description,
      if (request.priority != null) 'priority': request.priority!.wireValue,
      if (request.dueAt != null) 'dueAt': request.dueAt!.toIso8601String(),
      if (_hasText(request.assigneeUserId))
        'assigneeUserId': request.assigneeUserId!.trim(),
      if (_hasText(request.assigneeDisplayName))
        'assigneeDisplayName': request.assigneeDisplayName!.trim(),
      'clearDueAt': request.clearDueAt,
      'clearAssignee': request.clearAssignee,
    };
  }

  static Map<String, dynamic> workflowMetadataToJson(
    TaskWorkflowMetadataEntity metadata,
  ) {
    return <String, dynamic>{
      if (_hasText(metadata.contextType))
        'contextType': metadata.contextType!.trim(),
      if (_hasText(metadata.contextId)) 'contextId': metadata.contextId!.trim(),
      if (_hasText(metadata.sourceType))
        'sourceType': metadata.sourceType!.trim(),
      if (_hasText(metadata.sourceId)) 'sourceId': metadata.sourceId!.trim(),
      if (_hasText(metadata.sourceMessageId))
        'sourceMessageId': metadata.sourceMessageId!.trim(),
    };
  }

  static TaskWorkflowMetadataEntity? _workflowMetadataFromJson(Object? raw) {
    if (raw is! Map<String, dynamic>) {
      return null;
    }
    final metadata = TaskWorkflowMetadataEntity(
      contextType: _trimOrNull(raw['contextType']),
      contextId: _trimOrNull(raw['contextId']),
      sourceType: _trimOrNull(raw['sourceType']),
      sourceId: _trimOrNull(raw['sourceId']),
      sourceMessageId: _trimOrNull(raw['sourceMessageId']),
    );
    if (!_hasText(metadata.contextType) &&
        !_hasText(metadata.contextId) &&
        !_hasText(metadata.sourceType) &&
        !_hasText(metadata.sourceId) &&
        !_hasText(metadata.sourceMessageId)) {
      return null;
    }
    return metadata;
  }

  static DateTime? _parseDateTime(Object? raw) {
    final value = raw?.toString().trim() ?? '';
    if (value.isEmpty) {
      return null;
    }
    return DateTime.tryParse(value)?.toLocal();
  }

  static String? _trimOrNull(Object? raw) {
    final value = raw?.toString().trim() ?? '';
    return value.isEmpty ? null : value;
  }

  static bool _hasText(String? value) {
    return value != null && value.trim().isNotEmpty;
  }
}
