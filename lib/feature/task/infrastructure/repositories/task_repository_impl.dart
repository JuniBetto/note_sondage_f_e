import 'package:note_sondage/feature/task/domain/entities/task_create_request_entity.dart';
import 'package:note_sondage/feature/task/domain/entities/task_entity.dart';
import 'package:note_sondage/feature/task/domain/entities/task_status.dart';
import 'package:note_sondage/feature/task/domain/entities/task_update_request_entity.dart';
import 'package:note_sondage/feature/task/domain/repositories/task_repository.dart';
import 'package:note_sondage/feature/task/infrastructure/data_source/data_source_local/task_local_data_source.dart';
import 'package:note_sondage/feature/task/infrastructure/data_source/task_remote_data_source.dart';

class TaskRepositoryImpl implements TaskRepository {
  TaskRepositoryImpl(this._local, this._remote);

  final TaskLocalDataSource _local;
  final TaskRemoteDataSource _remote;

  @override
  Future<List<TaskEntity>> getLocalOnly() {
    return _local.getAll();
  }

  @override
  Future<List<TaskEntity>> getTasksByTeam(String teamId) async {
    try {
      final remote = await _remote.getTasksByTeam(teamId);
      await _replaceTeamSliceInCache(
        teamId: teamId,
        archived: false,
        incoming: remote,
      );
      return remote;
    } catch (e) {
      final cached = await _local.getAll();
      final localSlice = cached
          .where((task) => task.teamId == teamId && !task.isArchived)
          .toList();
      if (localSlice.isNotEmpty) {
        return localSlice;
      }
      throw Exception('Failed to fetch tasks: $e');
    }
  }

  @override
  Future<List<TaskEntity>> getArchivedTasksByTeam(String teamId) async {
    try {
      final remote = await _remote.getArchivedTasksByTeam(teamId);
      await _replaceTeamSliceInCache(
        teamId: teamId,
        archived: true,
        incoming: remote,
      );
      return remote;
    } catch (e) {
      final cached = await _local.getAll();
      final localSlice = cached
          .where((task) => task.teamId == teamId && task.isArchived)
          .toList();
      if (localSlice.isNotEmpty) {
        return localSlice;
      }
      throw Exception('Failed to fetch archived tasks: $e');
    }
  }

  @override
  Future<List<TaskEntity>> getMyTasks(String currentUserId) async {
    try {
      final remote = await _remote.getMyTasks();
      await _upsertAllInCache(remote);
      return remote;
    } catch (e) {
      final cached = await _local.getAll();
      final localSlice = cached
          .where(
            (task) =>
                !task.isArchived &&
                (task.createdByUserId == currentUserId ||
                    task.assigneeUserId == currentUserId),
          )
          .toList();
      if (localSlice.isNotEmpty) {
        return localSlice;
      }
      throw Exception('Failed to fetch my tasks: $e');
    }
  }

  @override
  Future<List<TaskEntity>> getMyArchivedTasks(String currentUserId) async {
    try {
      final remote = await _remote.getMyArchivedTasks();
      await _upsertAllInCache(remote);
      return remote;
    } catch (e) {
      final cached = await _local.getAll();
      final localSlice = cached
          .where(
            (task) =>
                task.isArchived &&
                (task.createdByUserId == currentUserId ||
                    task.assigneeUserId == currentUserId),
          )
          .toList();
      if (localSlice.isNotEmpty) {
        return localSlice;
      }
      throw Exception('Failed to fetch my archived tasks: $e');
    }
  }

  @override
  Future<TaskEntity> getTaskById(String taskId) async {
    try {
      final task = await _remote.getTaskById(taskId);
      await _upsertInCache(task);
      return task;
    } catch (e) {
      final cached = await _local.getAll();
      final local = cached.where((task) => task.id == taskId).firstOrNull;
      if (local != null) {
        return local;
      }
      throw Exception('Failed to fetch task: $e');
    }
  }

  @override
  Future<TaskEntity> createTask(TaskCreateRequestEntity request) async {
    final created = await _remote.createTask(request);
    await _upsertInCache(created);
    return created;
  }

  @override
  Future<TaskEntity> updateTask(
    String taskId,
    TaskUpdateRequestEntity request,
  ) async {
    final updated = await _remote.updateTask(taskId, request);
    await _upsertInCache(updated);
    return updated;
  }

  @override
  Future<TaskEntity> updateTaskStatus(String taskId, TaskStatus status) async {
    final updated = await _remote.updateTaskStatus(taskId, status);
    await _upsertInCache(updated);
    return updated;
  }

  @override
  Future<TaskEntity> archiveTask(String taskId) async {
    final archived = await _remote.archiveTask(taskId);
    await _upsertInCache(archived);
    return archived;
  }

  @override
  Future<TaskEntity> unarchiveTask(String taskId) async {
    final restored = await _remote.unarchiveTask(taskId);
    await _upsertInCache(restored);
    return restored;
  }

  @override
  Future<void> deleteTaskPermanently(String taskId) async {
    await _remote.deleteTaskPermanently(taskId);
    await _removeFromCache(taskId);
  }

  Future<void> _removeFromCache(String taskId) async {
    final cached = await _local.getAll();
    final next = cached.where((task) => task.id != taskId).toList();
    if (next.length != cached.length) {
      await _local.saveAll(next);
    }
  }

  Future<void> _upsertInCache(TaskEntity task) async {
    await _upsertAllInCache([task]);
  }

  Future<void> _upsertAllInCache(List<TaskEntity> tasks) async {
    if (tasks.isEmpty) {
      return;
    }
    final incomingIds = tasks.map((task) => task.id).toSet();
    final cached = await _local.getAll();
    final next = [
      for (final existing in cached)
        if (!incomingIds.contains(existing.id)) existing,
      ...tasks,
    ];
    await _local.saveAll(next);
  }

  Future<void> _replaceTeamSliceInCache({
    required String teamId,
    required bool archived,
    required List<TaskEntity> incoming,
  }) async {
    final cached = await _local.getAll();
    final rest = cached
        .where((task) => !(task.teamId == teamId && task.isArchived == archived))
        .toList();
    await _local.saveAll([...rest, ...incoming]);
  }
}
