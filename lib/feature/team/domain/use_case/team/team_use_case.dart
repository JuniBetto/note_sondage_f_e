import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';
import 'package:note_sondage/feature/team/domain/repositories/team_repository.dart';

class TeamUseCase {
  final TeamRepository repository;
  TeamUseCase(this.repository);

  Future<List<TeamEntity>> getAllTeams() async {
    try {
      return await repository.getAll();
    } catch (e) {
      throw Exception('Failed to fetch teams: $e');
    }
  }

  Future<List<TeamEntity>> getAllTeamsByUserId(String userId) async {
    try {
      return await repository.getAllByUserId(userId);
    } catch (e) {
      throw Exception('Failed to fetch teams by user ID: $e');
    }
  }

  Future<TeamEntity?> getTeamById(String id) async {
    try {
      return await repository.getById(id);
    } catch (e) {
      throw Exception('Failed to fetch team: $e');
    }
  }

  Future<TeamEntity> createTeam(TeamEntity team) async {
    try {
      return await repository.create(team);
    } catch (e) {
      throw Exception('Failed to create team: $e');
    }
  }

  Future<TeamEntity> createTeamByUser(TeamEntity team, String userId) async {
    try {
      return await repository.createByUser(team, userId);
    } catch (e) {
      throw Exception('Failed to create team by user: $e');
    }
  }

  Future<TeamUpdate> updateTeam(TeamUpdate team) async {
    try {
      return await repository.update(team);
    } catch (e) {
      throw Exception('Failed to update team: $e');
    }
  }

  Future<List<TeamEntity>> getLocalTeams() async {
    return await repository.getLocalOnly();
  }

  Future<bool> deleteTeam(String id) async {
    try {
      return await repository.delete(id);
    } catch (e) {
      throw Exception('Failed to delete team: $e');
    }
  }
}
