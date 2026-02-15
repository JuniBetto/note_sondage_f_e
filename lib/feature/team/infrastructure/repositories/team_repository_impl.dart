import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';
import 'package:note_sondage/feature/team/domain/repositories/team_repository.dart';
import 'package:note_sondage/feature/team/infrastructure/data_source/team_remote_data_source.dart';

class TeamRepositoryImpl implements TeamRepository {
  final TeamRemoteDataSource remoteDataSource;
  TeamRepositoryImpl(this.remoteDataSource);

  @override
  Future<bool> delete(String id) async {
    try {
      await remoteDataSource.delete(id);
      return true;
    } catch (e) {
      throw Exception('Failed to delete team: $e');
    }
  }

  @override
  Future<List<TeamEntity>> getAll() async {
    try {
      return await remoteDataSource.getAll();
    } catch (e) {
      throw Exception('Failed to fetch teams: $e');
    }
  }

  @override
  Future<List<TeamEntity>> getAllByUserId(String userId) async {
    try {
      return await remoteDataSource.getAllByUserId(userId);
    } catch (e) {
      throw Exception('Failed to fetch teams by user ID: $e');
    }
  }

  @override
  Future<TeamEntity?> getById(String id) async {
    try {
      return await remoteDataSource.getById(id);
    } catch (e) {
      throw Exception('Failed to fetch team: $e');
    }
  }

  @override
  Future<TeamEntity> create(TeamEntity team) async {
    try {
      return await remoteDataSource.create(team);
    } catch (e) {
      throw Exception('Failed to create team: $e');
    }
  }

  @override
  Future<TeamEntity> createByUser(TeamEntity team, String userId) async {
    try {
      return await remoteDataSource.createByUser(team, userId);
    } catch (e) {
      throw Exception('Failed to create team by user: $e');
    }
  }

  @override
  Future<TeamUpdate> update(TeamUpdate team) async {
    try {
      final updatedTeam = await remoteDataSource.updateTeamUpdater(
        team.id ?? '',
        team,
      );
      return updatedTeam;
    } catch (e) {
      throw Exception('Failed to update team: $e');
    }
  }
}
