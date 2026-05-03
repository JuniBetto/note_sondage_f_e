import 'package:note_sondage/feature/clocking/domain/entities/clocking_record_entity.dart';
import 'package:note_sondage/feature/clocking/domain/repositories/clocking_repository.dart';

class ClockingUseCase {
  final ClockingRepository repository;
  ClockingUseCase(this.repository);

  Future<List<ClockingRecordEntity>> getAllRecords() async {
    try {
      return await repository.getAll();
    } catch (e) {
      throw Exception('Failed to fetch clocking records: $e');
    }
  }

  Future<List<ClockingRecordEntity>> getRecordsByDate(DateTime date) async {
    try {
      return await repository.getByDate(date);
    } catch (e) {
      throw Exception('Failed to fetch clocking records by date: $e');
    }
  }

  Future<List<ClockingRecordEntity>> getRecordsByUserId(String userId) async {
    try {
      return await repository.getByUserId(userId);
    } catch (e) {
      throw Exception('Failed to fetch clocking records by user: $e');
    }
  }

  Future<List<ClockingRecordEntity>> getRecordsByTeamId(String teamId) async {
    try {
      return await repository.getByTeamId(teamId);
    } catch (e) {
      throw Exception('Failed to fetch clocking records by team: $e');
    }
  }

  Future<ClockingRecordEntity> clockIn({
    String? teamId,
    String? note,
  }) async {
    try {
      return await repository.clockIn(teamId: teamId, note: note);
    } catch (e) {
      throw Exception('Failed to clock in: $e');
    }
  }

  Future<ClockingRecordEntity> clockOut({String? teamId, String? note}) async {
    try {
      return await repository.clockOut(teamId: teamId, note: note);
    } catch (e) {
      throw Exception('Failed to clock out: $e');
    }
  }

  Future<ClockingRecordEntity> startBreak({String? teamId, String? note}) async {
    try {
      return await repository.startBreak(teamId: teamId, note: note);
    } catch (e) {
      throw Exception('Failed to start break: $e');
    }
  }

  Future<ClockingRecordEntity> stopBreak({String? teamId, String? note}) async {
    try {
      return await repository.stopBreak(teamId: teamId, note: note);
    } catch (e) {
      throw Exception('Failed to stop break: $e');
    }
  }

  Future<bool> deleteRecord(String id) async {
    try {
      return await repository.delete(id);
    } catch (e) {
      throw Exception('Failed to delete clocking record: $e');
    }
  }

  Future<ClockingRecordEntity> updateTeamRecord({
    required String id,
    DateTime? clockInAt,
    DateTime? clockOutAt,
    int? totalBreakMinutes,
    String? note,
  }) async {
    try {
      return await repository.updateTeamRecord(
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

  Future<ClockingRecordEntity> decommitTeamRecord(String id) async {
    try {
      return await repository.decommitTeamRecord(id);
    } catch (e) {
      throw Exception('Failed to decommit team clocking record: $e');
    }
  }

  Future<ClockingRecordEntity> commitTeamRecord(String id) async {
    try {
      return await repository.commitTeamRecord(id);
    } catch (e) {
      throw Exception('Failed to commit team clocking record: $e');
    }
  }
}
