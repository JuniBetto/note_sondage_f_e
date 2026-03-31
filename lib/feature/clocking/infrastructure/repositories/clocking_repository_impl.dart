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
      final local = await _local.getAll();
      if (local.isNotEmpty) {
        _remote.getAll().catchError((_) => <ClockingRecordEntity>[]);
        return local;
      }
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
  Future<ClockingRecordEntity> clockIn(String userId) async {
    try {
      return await _remote.clockIn(userId);
    } catch (e) {
      throw Exception('Failed to clock in: $e');
    }
  }

  @override
  Future<ClockingRecordEntity> clockOut(String userId) async {
    try {
      return await _remote.clockOut(userId);
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
}
