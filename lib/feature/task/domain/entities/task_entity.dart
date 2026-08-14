import 'package:note_sondage/feature/task/domain/entities/task_priority.dart';
import 'package:note_sondage/feature/task/domain/entities/task_status.dart';
import 'package:note_sondage/feature/task/domain/entities/task_workflow_metadata_entity.dart';

class TaskEntity {
  const TaskEntity({
    required this.id,
    required this.teamId,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.createdByUserId,
    required this.createdByDisplayName,
    required this.createdAt,
    required this.updatedAt,
    this.dueAt,
    this.assigneeUserId,
    this.assigneeDisplayName,
    this.workflowMetadata,
    this.completedAt,
    this.archivedAt,
  });

  final String id;
  final String teamId;
  final String title;
  final String? description;
  final TaskStatus status;
  final TaskPriority priority;
  final DateTime? dueAt;
  final String? assigneeUserId;
  final String? assigneeDisplayName;
  final String createdByUserId;
  final String? createdByDisplayName;
  final TaskWorkflowMetadataEntity? workflowMetadata;
  final DateTime? completedAt;
  final DateTime? archivedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isArchived => archivedAt != null;

  TaskEntity copyWith({
    String? id,
    String? teamId,
    String? title,
    String? description,
    TaskStatus? status,
    TaskPriority? priority,
    DateTime? dueAt,
    bool clearDueAt = false,
    String? assigneeUserId,
    bool clearAssigneeUserId = false,
    String? assigneeDisplayName,
    bool clearAssigneeDisplayName = false,
    String? createdByUserId,
    String? createdByDisplayName,
    TaskWorkflowMetadataEntity? workflowMetadata,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    DateTime? archivedAt,
    bool clearArchivedAt = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskEntity(
      id: id ?? this.id,
      teamId: teamId ?? this.teamId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      dueAt: clearDueAt ? null : (dueAt ?? this.dueAt),
      assigneeUserId: clearAssigneeUserId
          ? null
          : (assigneeUserId ?? this.assigneeUserId),
      assigneeDisplayName: clearAssigneeDisplayName
          ? null
          : (assigneeDisplayName ?? this.assigneeDisplayName),
      createdByUserId: createdByUserId ?? this.createdByUserId,
      createdByDisplayName: createdByDisplayName ?? this.createdByDisplayName,
      workflowMetadata: workflowMetadata ?? this.workflowMetadata,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      archivedAt: clearArchivedAt ? null : (archivedAt ?? this.archivedAt),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
