import 'package:dio/dio.dart';
import 'package:note_sondage/core/network/setup_dio.dart';
import 'package:note_sondage/feature/clocking/domain/entities/clocking_record_entity.dart';
import 'package:note_sondage/feature/clocking/infrastructure/data/clocking_mapper.dart';
import 'package:note_sondage/feature/clocking/infrastructure/data_source/data_source_local/clocking_local_data_source.dart';

class ClockingRemoteDataSource {
  final ClockingLocalDataSource localDataSource;
  final Dio _dio;

  ClockingRemoteDataSource(this.localDataSource, {Dio? dio})
    : _dio = dio ?? DioClient().dio;

  Future<List<ClockingRecordEntity>> getAll() async {
    try {
      final response = await _dio.get('/api/aggregate/clocking/my-records');
      final data = response.data as List<dynamic>? ?? const [];
      final records = data
          .map((item) => ClockingMapper.fromJson(Map<String, dynamic>.from(item)))
          .toList();
      await localDataSource.saveAll(records);
      return records;
    } catch (e) {
      throw Exception('Failed to fetch clocking records: $e');
    }
  }

  Future<List<ClockingRecordEntity>> getByDate(DateTime date) async {
    try {
      final dateOnly = DateTime(date.year, date.month, date.day);
      final formatted = dateOnly.toIso8601String().split('T').first;
      final response = await _dio.get(
        '/api/aggregate/clocking/my-records',
        queryParameters: {'fromDate': formatted, 'toDate': formatted},
      );
      final data = response.data as List<dynamic>? ?? const [];
      return data
          .map((item) => ClockingMapper.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch clocking records by date: $e');
    }
  }

  Future<List<ClockingRecordEntity>> getByUserId(String userId) async {
    final records = await getAll();
    return records.where((record) => record.userId == userId).toList();
  }

  Future<List<ClockingRecordEntity>> getByTeamId(String teamId) async {
    try {
      final response = await _dio.get(
        '/api/aggregate/clocking/my-records',
        queryParameters: {'teamId': teamId},
      );
      final data = response.data as List<dynamic>? ?? const [];
      return data
          .map((item) => ClockingMapper.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch clocking records by team: $e');
    }
  }

  Future<ClockingRecordEntity?> getById(String id) async {
    final records = await getAll();
    try {
      return records.firstWhere((record) => record.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<ClockingRecordEntity> clockIn({
    required String teamId,
    String? note,
  }) async {
    try {
      final response = await _dio.post(
        '/api/aggregate/clocking/clock-in',
        data: {'teamId': teamId, if (note != null && note.isNotEmpty) 'note': note},
      );
      final record = ClockingMapper.fromJson(
        Map<String, dynamic>.from(response.data as Map<String, dynamic>),
      );
      return record;
    } catch (e) {
      throw Exception('Failed to clock in: $e');
    }
  }

  Future<ClockingRecordEntity> clockOut({String? teamId, String? note}) async {
    try {
      final response = await _dio.post(
        '/api/aggregate/clocking/clock-out',
        data: {
          if (teamId != null && teamId.isNotEmpty) 'teamId': teamId,
          if (note != null && note.isNotEmpty) 'note': note,
        },
      );
      final record = ClockingMapper.fromJson(
        Map<String, dynamic>.from(response.data as Map<String, dynamic>),
      );
      return record;
    } catch (e) {
      throw Exception('Failed to clock out: $e');
    }
  }

  Future<void> delete(String id) async {
    throw UnsupportedError('Clocking delete is not supported by the backend');
  }
}
