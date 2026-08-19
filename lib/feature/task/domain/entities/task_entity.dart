import 'package:note_sondage/feature/task/domain/entities/task_priority.dart';
import 'package:note_sondage/feature/task/domain/entities/task_reminder_anchor.dart';
import 'package:note_sondage/feature/task/domain/entities/task_status.dart';
import 'package:note_sondage/feature/task/domain/entities/task_workflow_metadata_entity.dart';

class TaskEntity {
  const TaskEntity({
    required this.id,
    this.teamId,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.createdByUserId,
    required this.createdByDisplayName,
    required this.createdAt,
    required this.updatedAt,
    this.startAt,
    this.dueAt,
    this.assigneeUserId,
    this.assigneeDisplayName,
    this.workflowMetadata,
    this.completedAt,
    this.archivedAt,
    this.reminderOffsets = const <int>[],
    this.reminderAnchor = TaskReminderAnchor.dueAt,
  });

  final String id;
  final String? teamId;
  final String title;
  final String? description;
  final TaskStatus status;
  final TaskPriority priority;
  final DateTime? startAt;
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

  /// Minuti relativi (negativi = prima) a cui schedulare i promemoria
  /// dell'allarme, ancorati a [reminderAnchor].
  final List<int> reminderOffsets;

  /// Se i promemoria sono ancorati a [dueAt] o a [startAt].
  final TaskReminderAnchor reminderAnchor;

  /// Data/ora usata per calcolare i promemoria, in base a [reminderAnchor].
  DateTime? get reminderAnchorTime =>
      reminderAnchor == TaskReminderAnchor.startAt ? startAt : dueAt;

  bool get isArchived => archivedAt != null;

  /// A task with no team is personal: visible and manageable only by its
  /// creator, not scoped to any team's membership/roles.
  bool get isPersonal => teamId == null;

  TaskEntity copyWith({
    String? id,
    String? teamId,
    bool clearTeamId = false,
    String? title,
    String? description,
    TaskStatus? status,
    TaskPriority? priority,
    DateTime? startAt,
    bool clearStartAt = false,
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
    List<int>? reminderOffsets,
    TaskReminderAnchor? reminderAnchor,
  }) {
    return TaskEntity(
      id: id ?? this.id,
      teamId: clearTeamId ? null : (teamId ?? this.teamId),
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      startAt: clearStartAt ? null : (startAt ?? this.startAt),
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
      reminderOffsets: reminderOffsets ?? this.reminderOffsets,
      reminderAnchor: reminderAnchor ?? this.reminderAnchor,
    );
  }
}
