import 'package:note_sondage/feature/task/domain/entities/task_create_request_entity.dart';
import 'package:note_sondage/feature/task/domain/entities/task_entity.dart';
import 'package:note_sondage/feature/task/domain/entities/task_status.dart';
import 'package:note_sondage/feature/task/domain/entities/task_update_request_entity.dart';
import 'package:note_sondage/feature/task/domain/repositories/task_repository.dart';
import 'package:note_sondage/feature/task/infrastructure/data_source/task_remote_data_source.dart';

class TaskRepositoryImpl implements TaskRepository {
  TaskRepositoryImpl(this._remote);

  final TaskRemoteDataSource _remote;

  @override
  Future<List<TaskEntity>> getTasksByTeam(String teamId) {
    return _remote.getTasksByTeam(teamId);
  }

  @override
  Future<TaskEntity> getTaskById(String taskId) {
    return _remote.getTaskById(taskId);
  }

  @override
  Future<TaskEntity> createTask(TaskCreateRequestEntity request) {
    return _remote.createTask(request);
  }

  @override
  Future<TaskEntity> updateTask(
    String taskId,
    TaskUpdateRequestEntity request,
  ) {
    return _remote.updateTask(taskId, request);
  }

  @override
  Future<TaskEntity> updateTaskStatus(String taskId, TaskStatus status) {
    return _remote.updateTaskStatus(taskId, status);
  }

  @override
  Future<TaskEntity> archiveTask(String taskId) {
    return _remote.archiveTask(taskId);
  }
}
