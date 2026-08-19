import 'package:note_sondage/feature/task/domain/entities/task_priority.dart';
import 'package:note_sondage/feature/task/domain/entities/task_reminder_anchor.dart';

class TaskUpdateRequestEntity {
  const TaskUpdateRequestEntity({
    this.title,
    this.description,
    this.priority,
    this.startAt,
    this.dueAt,
    this.assigneeUserId,
    this.assigneeDisplayName,
    this.clearStartAt = false,
    this.clearDueAt = false,
    this.clearAssignee = false,
    this.reminderOffsets,
    this.reminderAnchor,
  });

  final String? title;
  final String? description;
  final TaskPriority? priority;
  final DateTime? startAt;
  final DateTime? dueAt;
  final String? assigneeUserId;
  final String? assigneeDisplayName;
  final bool clearStartAt;
  final bool clearDueAt;
  final bool clearAssignee;

  /// `null` = non modificare i promemoria esistenti; una lista (anche vuota)
  /// sostituisce gli offset attuali.
  final List<int>? reminderOffsets;
  final TaskReminderAnchor? reminderAnchor;
}
