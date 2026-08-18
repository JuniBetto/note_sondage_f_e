import 'package:dio/dio.dart';
import 'package:note_sondage/core/network/setup_dio.dart';
import 'package:note_sondage/feature/task/domain/entities/task_create_request_entity.dart';
import 'package:note_sondage/feature/task/domain/entities/task_entity.dart';
import 'package:note_sondage/feature/task/domain/entities/task_status.dart';
import 'package:note_sondage/feature/task/domain/entities/task_update_request_entity.dart';
import 'package:note_sondage/feature/task/infrastructure/data/task_mapper.dart';

class TaskRemoteDataSource {
  TaskRemoteDataSource({Dio? dio}) : _dio = dio ?? DioClient().dio;

  final Dio _dio;

  Future<List<TaskEntity>> getTasksByTeam(String teamId) async {
    final response = await _dio.get(
      '/api/tasks',
      queryParameters: {'teamId': teamId},
    );
    final data = response.data as List<dynamic>? ?? const <dynamic>[];
    return data
        .whereType<Map<String, dynamic>>()
        .map(TaskMapper.fromJson)
        .toList(growable: false);
  }

  Future<List<TaskEntity>> getArchivedTasksByTeam(String teamId) async {
    final response = await _dio.get(
      '/api/tasks/archived',
      queryParameters: {'teamId': teamId},
    );
    final data = response.data as List<dynamic>? ?? const <dynamic>[];
    return data
        .whereType<Map<String, dynamic>>()
        .map(TaskMapper.fromJson)
        .toList(growable: false);
  }

  Future<TaskEntity> getTaskById(String taskId) async {
    final response = await _dio.get('/api/tasks/$taskId');
    return TaskMapper.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<TaskEntity> createTask(TaskCreateRequestEntity request) async {
    final response = await _dio.post(
      '/api/tasks',
      data: TaskMapper.createRequestToJson(request),
    );
    return TaskMapper.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<TaskEntity> updateTask(
    String taskId,
    TaskUpdateRequestEntity request,
  ) async {
    final response = await _dio.patch(
      '/api/tasks/$taskId',
      data: TaskMapper.updateRequestToJson(request),
    );
    return TaskMapper.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<TaskEntity> updateTaskStatus(String taskId, TaskStatus status) async {
    final response = await _dio.patch(
      '/api/tasks/$taskId/status',
      data: {'status': status.wireValue},
    );
    return TaskMapper.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<TaskEntity> archiveTask(String taskId) async {
    final response = await _dio.post('/api/tasks/$taskId/archive');
    return TaskMapper.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<TaskEntity> unarchiveTask(String taskId) async {
    final response = await _dio.post('/api/tasks/$taskId/unarchive');
    return TaskMapper.fromJson(Map<String, dynamic>.from(response.data));
  }
}
