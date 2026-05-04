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
        '/api/aggregate/clocking/team-records',
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
    String? teamId,
    String? note,
  }) async {
    try {
      final clockInAt = DateTime.now();
      final response = await _dio.post(
        '/api/aggregate/clocking/clock-in',
        data: {
          if (teamId != null && teamId.isNotEmpty) 'teamId': teamId,
          if (note != null && note.isNotEmpty) 'note': note,
          'clockInAt': clockInAt.toIso8601String(),
        },
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
      final clockOutAt = DateTime.now();
      final response = await _dio.post(
        '/api/aggregate/clocking/clock-out',
        data: {
          if (teamId != null && teamId.isNotEmpty) 'teamId': teamId,
          if (note != null && note.isNotEmpty) 'note': note,
          'clockOutAt': clockOutAt.toIso8601String(),
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

  Future<ClockingRecordEntity> startBreak({String? teamId, String? note}) async {
    try {
      final actionAt = DateTime.now();
      final response = await _dio.post(
        '/api/aggregate/clocking/start-break',
        data: {
          if (teamId != null && teamId.isNotEmpty) 'teamId': teamId,
          if (note != null && note.isNotEmpty) 'note': note,
          'actionAt': actionAt.toIso8601String(),
        },
      );
      return ClockingMapper.fromJson(
        Map<String, dynamic>.from(response.data as Map<String, dynamic>),
      );
    } catch (e) {
      throw Exception('Failed to start break: $e');
    }
  }

  Future<ClockingRecordEntity> stopBreak({String? teamId, String? note}) async {
    try {
      final actionAt = DateTime.now();
      final response = await _dio.post(
        '/api/aggregate/clocking/stop-break',
        data: {
          if (teamId != null && teamId.isNotEmpty) 'teamId': teamId,
          if (note != null && note.isNotEmpty) 'note': note,
          'actionAt': actionAt.toIso8601String(),
        },
      );
      return ClockingMapper.fromJson(
        Map<String, dynamic>.from(response.data as Map<String, dynamic>),
      );
    } catch (e) {
      throw Exception('Failed to stop break: $e');
    }
  }

  Future<void> delete(String id) async {
    throw UnsupportedError('Clocking delete is not supported by the backend');
  }

  Future<ClockingRecordEntity> updateTeamRecord({
    required String id,
    DateTime? clockInAt,
    DateTime? clockOutAt,
    int? totalBreakMinutes,
    String? note,
  }) async {
    try {
      final response = await _dio.patch(
        '/api/aggregate/clocking/records/$id',
        data: {
          if (clockInAt != null) 'clockInAt': clockInAt.toIso8601String(),
          if (clockOutAt != null) 'clockOutAt': clockOutAt.toIso8601String(),
          if (totalBreakMinutes != null) 'totalBreakMinutes': totalBreakMinutes,
          if (note != null) 'note': note,
        },
      );
      return ClockingMapper.fromJson(
        Map<String, dynamic>.from(response.data as Map<String, dynamic>),
      );
    } catch (e) {
      throw Exception('Failed to update team clocking record: $e');
    }
  }

  Future<ClockingRecordEntity> decommitTeamRecord(String id) async {
    try {
      final response = await _dio.post('/api/aggregate/clocking/records/$id/decommit');
      return ClockingMapper.fromJson(
        Map<String, dynamic>.from(response.data as Map<String, dynamic>),
      );
    } catch (e) {
      throw Exception('Failed to decommit team clocking record: $e');
    }
  }

  Future<ClockingRecordEntity> commitTeamRecord(String id) async {
    try {
      final response = await _dio.post('/api/aggregate/clocking/records/$id/commit');
      return ClockingMapper.fromJson(
        Map<String, dynamic>.from(response.data as Map<String, dynamic>),
      );
    } catch (e) {
      throw Exception('Failed to commit team clocking record: $e');
    }
  }
}
