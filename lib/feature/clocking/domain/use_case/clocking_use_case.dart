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
    DateTime? clockInAt,
  }) async {
    try {
      return await repository.clockIn(
        teamId: teamId,
        note: note,
        clockInAt: clockInAt,
      );
    } catch (e) {
      throw Exception('Failed to clock in: $e');
    }
  }

  Future<ClockingRecordEntity> clockOut({
    String? teamId,
    String? note,
    DateTime? clockOutAt,
  }) async {
    try {
      return await repository.clockOut(
        teamId: teamId,
        note: note,
        clockOutAt: clockOutAt,
      );
    } catch (e) {
      throw Exception('Failed to clock out: $e');
    }
  }

  Future<ClockingRecordEntity> startBreak({
    String? teamId,
    String? note,
    DateTime? actionAt,
  }) async {
    try {
      return await repository.startBreak(
        teamId: teamId,
        note: note,
        actionAt: actionAt,
      );
    } catch (e) {
      throw Exception('Failed to start break: $e');
    }
  }

  Future<ClockingRecordEntity> stopBreak({
    String? teamId,
    String? note,
    DateTime? actionAt,
  }) async {
    try {
      return await repository.stopBreak(
        teamId: teamId,
        note: note,
        actionAt: actionAt,
      );
    } catch (e) {
      throw Exception('Failed to stop break: $e');
    }
  }

  Future<ClockingRecordEntity> markVacation({
    String? teamId,
    required DateTime date,
    String? targetUserId,
    String? note,
  }) async {
    try {
      return await repository.markVacation(
        teamId: teamId,
        date: date,
        targetUserId: targetUserId,
        note: note,
      );
    } catch (e) {
      throw Exception('Failed to mark vacation: $e');
    }
  }

  Future<ClockingRecordEntity> markPermission({
    String? teamId,
    required DateTime date,
    required String startTime,
    required String endTime,
    String? targetUserId,
    String? note,
  }) async {
    try {
      return await repository.markPermission(
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

  Future<int> createManualClockingEntries({
    String? teamId,
    required List<DateTime> dates,
    required int clockInMinutes,
    required int clockOutMinutes,
    required int breakMinutes,
    String? note,
  }) async {
    try {
      if (dates.isEmpty) {
        throw Exception('Select at least one day.');
      }
      if (clockOutMinutes <= clockInMinutes) {
        throw Exception('Clock-out time must be after clock-in time.');
      }
      final durationMinutes = clockOutMinutes - clockInMinutes;
      if (breakMinutes < 0 || breakMinutes >= durationMinutes) {
        throw Exception('Break time must be shorter than the shift duration.');
      }

      final normalizedDates =
          dates
              .map((date) => DateTime(date.year, date.month, date.day))
              .toSet()
              .toList()
            ..sort();
      final today = DateTime.now();
      final normalizedToday = DateTime(today.year, today.month, today.day);

      if (normalizedDates.any(
        (date) =>
            date.year == normalizedToday.year &&
            date.month == normalizedToday.month &&
            date.day == normalizedToday.day,
      )) {
        throw Exception(
          'Manual clocking is only available for days different from today.',
        );
      }

      var createdCount = 0;
      for (final date in normalizedDates) {
        final clockInAt = date.add(Duration(minutes: clockInMinutes));
        final clockOutAt = date.add(Duration(minutes: clockOutMinutes));

        await repository.clockIn(teamId: teamId, clockInAt: clockInAt);

        if (breakMinutes > 0) {
          final breakStartAt = clockOutAt.subtract(
            Duration(minutes: breakMinutes),
          );
          await repository.startBreak(teamId: teamId, actionAt: breakStartAt);
          await repository.stopBreak(teamId: teamId, actionAt: clockOutAt);
        }

        await repository.clockOut(
          teamId: teamId,
          note: note,
          clockOutAt: clockOutAt,
        );
        createdCount += 1;
      }

      return createdCount;
    } catch (e) {
      throw Exception('Failed to create manual clocking entries: $e');
    }
  }

  Future<void> requestTeamMemberClocking({
    required String teamId,
    required String targetUserId,
    required DateTime date,
    String? note,
  }) async {
    try {
      await repository.requestTeamMemberClocking(
        teamId: teamId,
        targetUserId: targetUserId,
        date: date,
        note: note,
      );
    } catch (e) {
      throw Exception('Failed to request team member clocking: $e');
    }
  }

  Future<void> requestDecommit({
    required String teamId,
    required String targetUserId,
    required DateTime date,
    required String recordId,
    String? note,
  }) async {
    try {
      await repository.requestDecommit(
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

  Future<void> requestVacation({
    required String teamId,
    required DateTime date,
    String? note,
  }) async {
    try {
      await repository.requestVacation(teamId: teamId, date: date, note: note);
    } catch (e) {
      throw Exception('Failed to request vacation: $e');
    }
  }

  Future<void> requestPermission({
    required String teamId,
    required DateTime date,
    required String startTime,
    required String endTime,
    String? note,
  }) async {
    try {
      await repository.requestPermission(
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
