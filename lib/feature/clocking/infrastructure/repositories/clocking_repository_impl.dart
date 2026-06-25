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
    String? teamId,
    String? note,
    DateTime? clockInAt,
  }) async {
    try {
      return await _remote.clockIn(
        teamId: teamId,
        note: note,
        clockInAt: clockInAt,
      );
    } catch (e) {
      throw Exception('Failed to clock in: $e');
    }
  }

  @override
  Future<ClockingRecordEntity> clockOut({
    String? teamId,
    String? note,
    DateTime? clockOutAt,
  }) async {
    try {
      return await _remote.clockOut(
        teamId: teamId,
        note: note,
        clockOutAt: clockOutAt,
      );
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
  Future<ClockingRecordEntity> startBreak({
    String? teamId,
    String? note,
    DateTime? actionAt,
  }) async {
    try {
      return await _remote.startBreak(
        teamId: teamId,
        note: note,
        actionAt: actionAt,
      );
    } catch (e) {
      throw Exception('Failed to start break: $e');
    }
  }

  @override
  Future<ClockingRecordEntity> stopBreak({
    String? teamId,
    String? note,
    DateTime? actionAt,
  }) async {
    try {
      return await _remote.stopBreak(
        teamId: teamId,
        note: note,
        actionAt: actionAt,
      );
    } catch (e) {
      throw Exception('Failed to stop break: $e');
    }
  }

  @override
  Future<ClockingRecordEntity> markVacation({
    String? teamId,
    required DateTime date,
    String? targetUserId,
    String? note,
  }) async {
    try {
      return await _remote.markVacation(
        teamId: teamId,
        date: date,
        targetUserId: targetUserId,
        note: note,
      );
    } catch (e) {
      throw Exception('Failed to mark vacation: $e');
    }
  }

  @override
  Future<ClockingRecordEntity> markPermission({
    String? teamId,
    required DateTime date,
    required String startTime,
    required String endTime,
    String? targetUserId,
    String? note,
  }) async {
    try {
      return await _remote.markPermission(
        teamId: teamId,
        date: date,
        startTime: startTime,
        endTime: endTime,
        targetUserId: targetUserId,
        note: note,
      );
    } catch (e) {
      throw Exception('Failed to mark permission: $e');
    }
  }

  @override
  Future<int> createManualClockingEntries({
    String? teamId,
    required List<DateTime> dates,
    required int clockInMinutes,
    required int clockOutMinutes,
    required int breakMinutes,
    String? note,
  }) async {
    try {
      return await _remote.createManualClockingEntries(
        teamId: teamId,
        dates: dates,
        clockInMinutes: clockInMinutes,
        clockOutMinutes: clockOutMinutes,
        breakMinutes: breakMinutes,
        note: note,
      );
    } catch (e) {
      throw Exception('Failed to create manual clocking entries: $e');
    }
  }

  @override
  Future<void> requestTeamMemberClocking({
    required String teamId,
    required String targetUserId,
    required DateTime date,
    String? note,
  }) async {
    try {
      await _remote.requestTeamMemberClocking(
        teamId: teamId,
        targetUserId: targetUserId,
        date: date,
        note: note,
      );
    } catch (e) {
      throw Exception('Failed to request team member clocking: $e');
    }
  }

  @override
  Future<void> requestDecommit({
    required String teamId,
    required String targetUserId,
    required DateTime date,
    required String recordId,
    String? note,
  }) async {
    try {
      await _remote.requestDecommit(
        teamId: teamId,
        targetUserId: targetUserId,
        date: date,
        recordId: recordId,
        note: note,
      );
    } catch (e) {
      throw Exception('Failed to request decommit: $e');
    }
  }

  @override
  Future<void> requestVacation({
    required String teamId,
    required DateTime date,
    String? note,
  }) async {
    try {
      await _remote.requestVacation(teamId: teamId, date: date, note: note);
    } catch (e) {
      throw Exception('Failed to request vacation: $e');
    }
  }

  @override
  Future<void> requestPermission({
    required String teamId,
    required DateTime date,
    required String startTime,
    required String endTime,
    String? note,
  }) async {
    try {
      await _remote.requestPermission(
        teamId: teamId,
        date: date,
        startTime: startTime,
        endTime: endTime,
        note: note,
      );
    } catch (e) {
      throw Exception('Failed to request permission: $e');
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
