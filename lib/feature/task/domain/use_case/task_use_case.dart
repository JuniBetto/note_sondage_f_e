import 'package:note_sondage/feature/task/domain/entities/task_create_request_entity.dart';
import 'package:note_sondage/feature/task/domain/entities/task_entity.dart';
import 'package:note_sondage/feature/task/domain/entities/task_status.dart';
import 'package:note_sondage/feature/task/domain/entities/task_update_request_entity.dart';
import 'package:note_sondage/feature/task/domain/repositories/task_repository.dart';

class TaskUseCase {
  TaskUseCase(this._repository);

  final TaskRepository _repository;

  Future<List<TaskEntity>> getTasksByTeam(String teamId) {
    return _repository.getTasksByTeam(teamId);
  }

  Future<List<TaskEntity>> getArchivedTasksByTeam(String teamId) {
    return _repository.getArchivedTasksByTeam(teamId);
  }

  Future<TaskEntity> getTaskById(String taskId) {
    return _repository.getTaskById(taskId);
  }

  Future<TaskEntity> createTask(TaskCreateRequestEntity request) {
    return _repository.createTask(request);
  }

  Future<TaskEntity> updateTask(
    String taskId,
    TaskUpdateRequestEntity request,
  ) {
    return _repository.updateTask(taskId, request);
  }

  Future<TaskEntity> updateTaskStatus(String taskId, TaskStatus status) {
    return _repository.updateTaskStatus(taskId, status);
  }

  Future<TaskEntity> archiveTask(String taskId) {
    return _repository.archiveTask(taskId);
  }

  Future<TaskEntity> unarchiveTask(String taskId) {
    return _repository.unarchiveTask(taskId);
  }
}
