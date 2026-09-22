import 'package:note_sondage/feature/task/domain/entities/task_create_request_entity.dart';
import 'package:note_sondage/feature/task/domain/entities/task_entity.dart';
import 'package:note_sondage/feature/task/domain/entities/task_reminder_anchor.dart';
import 'package:note_sondage/feature/task/domain/entities/task_status.dart';
import 'package:note_sondage/feature/task/domain/entities/task_update_request_entity.dart';

abstract class TaskRepository {
  Future<List<TaskEntity>> getLocalOnly();

  Future<List<TaskEntity>> getTasksByTeam(String teamId);

  Future<List<TaskEntity>> getArchivedTasksByTeam(String teamId);

  /// Active tasks created by or assigned to [currentUserId], across every
  /// team they belong to plus their personal (team-less) tasks.
  Future<List<TaskEntity>> getMyTasks(String currentUserId);

  Future<List<TaskEntity>> getMyArchivedTasks(String currentUserId);

  Future<TaskEntity> getTaskById(String taskId);

  Future<TaskEntity> createTask(TaskCreateRequestEntity request);

  Future<TaskEntity> updateTask(String taskId, TaskUpdateRequestEntity request);

  /// Sets the current user's own reminder for this task, independent of
  /// anyone else's (e.g. the creator's, when the caller is the assignee).
  Future<TaskEntity> updateMyReminder(
    String taskId,
    List<int> reminderOffsets,
    TaskReminderAnchor reminderAnchor,
  );

  Future<TaskEntity> updateTaskStatus(String taskId, TaskStatus status);

  Future<TaskEntity> archiveTask(String taskId);

  Future<TaskEntity> unarchiveTask(String taskId);

  /// Permanently removes a canceled or archived task. Irreversible.
  Future<void> deleteTaskPermanently(String taskId);
}
