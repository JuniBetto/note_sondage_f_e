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

  Future<ClockingRecordEntity> clockIn(String userId) async {
    try {
      return await repository.clockIn(userId);
    } catch (e) {
      throw Exception('Failed to clock in: $e');
    }
  }

  Future<ClockingRecordEntity> clockOut(String userId) async {
    try {
      return await repository.clockOut(userId);
    } catch (e) {
      throw Exception('Failed to clock out: $e');
    }
  }

  Future<bool> deleteRecord(String id) async {
    try {
      return await repository.delete(id);
    } catch (e) {
      throw Exception('Failed to delete clocking record: $e');
    }
  }
}
