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
      final cached = await _local.getAll();
      await _local.saveAll(cached.where((team) => team.id != id).toList());
      return true;
    } catch (e) {
      throw Exception('Failed to delete team: $e');
    }
  }

  @override
  Future<List<TeamEntity>> getLocalOnly() async {
    return await _local.getAll();
  }

  @override
  Future<List<TeamEntity>> getAll() async {
    try {
      final remote = await _remote.getAll();
      await _local.saveAll(remote);
      return remote;
    } catch (e) {
      final cached = await _local.getAll();
      if (cached.isNotEmpty) return cached;
      throw Exception('Failed to fetch teams: $e');
    }
  }

  @override
  Future<List<TeamEntity>> getAllByUserId(String userId) async {
    try {
      final remote = await _remote.getAllByUserId(userId);
      await _local.saveAll(remote);
      return remote;
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
      // Fallback: find in local cache if remote fails
      final cached = await _local.getAll();
      return cached.where((t) => t.id == id).firstOrNull;
    }
  }

  @override
  Future<TeamEntity> create(TeamEntity team) async {
    try {
      final created = await _remote.create(team);
      final cached = await _local.getAll();
      await _local.saveAll([...cached, created]);
      return created;
    } catch (e) {
      throw Exception('Failed to create team: $e');
    }
  }

  @override
  Future<TeamEntity> createByUser(TeamEntity team, String userId) async {
    try {
      final created = await _remote.createByUser(team, userId);
      final cached = await _local.getAll();
      await _local.saveAll([...cached, created]);
      return created;
    } catch (e) {
      throw Exception('Failed to create team by user: $e');
    }
  }

  @override
  Future<TeamUpdate> update(TeamUpdate team) async {
    try {
      final updated = await _remote.updateTeamUpdater(team.id ?? '', team);
      final cached = await _local.getAll();
      final next = cached
          .map(
            (t) => t.id == updated.id
                ? TeamEntity(
                    updated.id,
                    updated.color,
                    null,
                    name: updated.name,
                    description: updated.description,
                    createdByUserId: updated.createdByUserId,
                    createdAt: updated.createdAt,
                  )
                : t,
          )
          .toList();
      await _local.saveAll(next);
      return updated;
    } catch (e) {
      throw Exception('Failed to update team: $e');
    }
  }

  Future<void> refreshAll() async {
    await _remote.getAll();
  }
}
