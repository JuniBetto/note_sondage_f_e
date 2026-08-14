import 'package:note_sondage/feature/task/domain/entities/task_priority.dart';
import 'package:note_sondage/feature/task/domain/entities/task_workflow_metadata_entity.dart';

class TaskCreateRequestEntity {
  const TaskCreateRequestEntity({
    required this.teamId,
    required this.title,
    this.description,
    this.priority = TaskPriority.medium,
    this.dueAt,
    this.assigneeUserId,
    this.assigneeDisplayName,
    this.createdByUserId,
    this.createdByDisplayName,
    this.workflowMetadata,
  });

  final String teamId;
  final String title;
  final String? description;
  final TaskPriority priority;
  final DateTime? dueAt;
  final String? assigneeUserId;
  final String? assigneeDisplayName;
  final String? createdByUserId;
  final String? createdByDisplayName;
  final TaskWorkflowMetadataEntity? workflowMetadata;

  TaskCreateRequestEntity copyWith({
    String? teamId,
    String? title,
    String? description,
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
  }) {
    return TaskCreateRequestEntity(
      teamId: teamId ?? this.teamId,
      title: title ?? this.title,
      description: description ?? this.description,
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
    );
  }
}
