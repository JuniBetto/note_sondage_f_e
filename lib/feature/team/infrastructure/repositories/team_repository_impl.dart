import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';
import 'package:note_sondage/feature/team/domain/repositories/team_repository.dart';
import 'package:note_sondage/feature/team/infrastructure/data_source/data_source_local/team_local_data_source.dart';
import 'package:note_sondage/feature/team/infrastructure/data_source/data_source_remote/team_remote_data_source.dart';

class TeamRepositoryImpl implements TeamRepository {
  final TeamLocalDataSource _local;
  final TeamRemoteDataSource _remote;

  TeamRepositoryImpl(this._local, this._remote);

  @override
  Future<bool> delete(String id) async {
    try {
      await _remote.delete(id);
      return true;
    } catch (e) {
      throw Exception('Failed to delete team: $e');
    }
  }

  @override
  Future<List<TeamEntity>> getAll() async {
    try {
      final local = await _local.getAll();
      if (local.isNotEmpty) {
        _remote.getAll().catchError((_) => <TeamEntity>[]);
        return local;
      }
      return await _remote.getAll();
    } catch (e) {
      final cached = await _local.getAll();
      if (cached.isNotEmpty) return cached;
      throw Exception('Failed to fetch teams: $e');
    }
  }

  @override
  Future<List<TeamEntity>> getAllByUserId(String userId) async {
    try {
      final local = await _local.getAll();
      if (local.isNotEmpty) {
        _remote.getAllByUserId(userId).catchError((_) => <TeamEntity>[]);
        return local;
      }
      return await _remote.getAllByUserId(userId);
    } catch (e) {
      final cached = await _local.getAll();
      if (cached.isNotEmpty) return cached;
      throw Exception('Failed to fetch teams by user ID: $e');
    }
  }

  @override
  Future<TeamEntity?> getById(String id) async {
    try {
      return await _remote.getById(id);
    } catch (e) {
      throw Exception('Failed to fetch team: $e');
    }
  }

  @override
  Future<TeamEntity> create(TeamEntity team) async {
    try {
      return await _remote.create(team);
    } catch (e) {
      throw Exception('Failed to create team: $e');
    }
  }

  @override
  Future<TeamEntity> createByUser(TeamEntity team, String userId) async {
    try {
      return await _remote.createByUser(team, userId);
    } catch (e) {
      throw Exception('Failed to create team by user: $e');
    }
  }

  @override
  Future<TeamUpdate> update(TeamUpdate team) async {
    try {
      return await _remote.updateTeamUpdater(team.id ?? '', team);
    } catch (e) {
      throw Exception('Failed to update team: $e');
    }
  }

  Future<void> refreshAll() async {
    await _remote.getAll();
  }
}
