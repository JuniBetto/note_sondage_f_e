import 'package:note_sondage/feature/clocking/domain/entities/clocking_record_entity.dart';
import 'package:note_sondage/feature/clocking/domain/repositories/clocking_repository.dart';
import 'package:note_sondage/feature/clocking/infrastructure/data_source/data_source_local/clocking_local_data_source.dart';
import 'package:note_sondage/feature/clocking/infrastructure/data_source/data_source_remote/clocking_remote_data_source.dart';

class ClockingRepositoryImpl implements ClockingRepository {
  final ClockingLocalDataSource _local;
  final ClockingRemoteDataSource _remote;

  ClockingRepositoryImpl(this._local, this._remote);

  @override
  Future<List<ClockingRecordEntity>> getAll() async {
    try {
      return await _remote.getAll();
    } catch (e) {
      final cached = await _local.getAll();
      if (cached.isNotEmpty) return cached;
      throw Exception('Failed to fetch clocking records: $e');
    }
  }

  @override
  Future<List<ClockingRecordEntity>> getByDate(DateTime date) async {
    try {
      return await _remote.getByDate(date);
    } catch (e) {
      throw Exception('Failed to fetch clocking records by date: $e');
    }
  }

  @override
  Future<List<ClockingRecordEntity>> getByUserId(String userId) async {
    try {
      return await _remote.getByUserId(userId);
    } catch (e) {
      throw Exception('Failed to fetch clocking records by user: $e');
    }
  }

  @override
  Future<List<ClockingRecordEntity>> getByTeamId(String teamId) async {
    try {
      return await _remote.getByTeamId(teamId);
    } catch (e) {
      throw Exception('Failed to fetch clocking records by team: $e');
    }
  }

  @override
  Future<ClockingRecordEntity> clockIn({
    required String teamId,
    String? note,
  }) async {
    try {
      return await _remote.clockIn(teamId: teamId, note: note);
    } catch (e) {
      throw Exception('Failed to clock in: $e');
    }
  }

  @override
  Future<ClockingRecordEntity> clockOut({String? teamId, String? note}) async {
    try {
      return await _remote.clockOut(teamId: teamId, note: note);
    } catch (e) {
      throw Exception('Failed to clock out: $e');
    }
  }

  @override
  Future<ClockingRecordEntity?> getById(String id) async {
    try {
      return await _remote.getById(id);
    } catch (e) {
      throw Exception('Failed to fetch clocking record: $e');
    }
  }

  @override
  Future<bool> delete(String id) async {
    try {
      await _remote.delete(id);
      return true;
    } catch (e) {
      throw Exception('Failed to delete clocking record: $e');
    }
  }

  @override
  Future<ClockingRecordEntity> startBreak({String? teamId, String? note}) async {
    try {
      return await _remote.startBreak(teamId: teamId, note: note);
    } catch (e) {
      throw Exception('Failed to start break: $e');
    }
  }

  @override
  Future<ClockingRecordEntity> stopBreak({String? teamId, String? note}) async {
    try {
      return await _remote.stopBreak(teamId: teamId, note: note);
    } catch (e) {
      throw Exception('Failed to stop break: $e');
    }
  }

  @override
  Future<ClockingRecordEntity> updateTeamRecord({
    required String id,
    DateTime? clockInAt,
    DateTime? clockOutAt,
    int? totalBreakMinutes,
    String? note,
  }) async {
    try {
      return await _remote.updateTeamRecord(
        id: id,
        clockInAt: clockInAt,
        clockOutAt: clockOutAt,
        totalBreakMinutes: totalBreakMinutes,
        note: note,
      );
    } catch (e) {
      throw Exception('Failed to update team clocking record: $e');
    }
  }

  @override
  Future<ClockingRecordEntity> decommitTeamRecord(String id) async {
    try {
      return await _remote.decommitTeamRecord(id);
    } catch (e) {
      throw Exception('Failed to decommit team clocking record: $e');
    }
  }

  @override
  Future<ClockingRecordEntity> commitTeamRecord(String id) async {
    try {
      return await _remote.commitTeamRecord(id);
    } catch (e) {
      throw Exception('Failed to commit team clocking record: $e');
    }
  }
}
