import 'package:note_sondage/feature/task/domain/entities/task_priority.dart';

class TaskUpdateRequestEntity {
  const TaskUpdateRequestEntity({
    this.title,
    this.description,
    this.priority,
    this.dueAt,
    this.assigneeUserId,
    this.assigneeDisplayName,
    this.clearDueAt = false,
    this.clearAssignee = false,
  });

  final String? title;
  final String? description;
  final TaskPriority? priority;
  final DateTime? dueAt;
  final String? assigneeUserId;
  final String? assigneeDisplayName;
  final bool clearDueAt;
  final bool clearAssignee;
}
