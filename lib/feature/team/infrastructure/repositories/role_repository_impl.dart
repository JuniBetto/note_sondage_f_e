import 'package:note_sondage/feature/team/domain/entities/role_entity.dart';
import 'package:note_sondage/feature/team/domain/repositories/role_repository.dart';
import 'package:note_sondage/feature/team/infrastructure/data_source/data_source_local/role_local_data_source.dart';
import 'package:note_sondage/feature/team/infrastructure/data_source/data_source_remote/role_remote_data_source.dart';

class RoleRepositoryImpl implements RoleRepository {
  final RoleLocalDataSource _local;
  final RoleRemoteDataSource _remote;

  RoleRepositoryImpl(this._local, this._remote);

  @override
  Future<bool> deleteRole(String id) async {
    try {
      await _remote.delete(id);
      return true;
    } catch (e) {
      throw Exception('Failed to delete role: $e');
    }
  }

  @override
  Future<List<RoleEntity>> getAll() async {
    try {
      // Return cached immediately; refresh in background if available
      final local = (await _local.getAll())
          .where((role) => role.teamId.isEmpty)
          .toList();
      if (local.isNotEmpty) {
        _remote.refreshRoles().catchError((_) => <RoleEntity>[]);
        return local;
      }
      // Cache is empty — fetch from remote and save
      return await _remote.refreshRoles();
    } catch (e) {
      final cached = (await _local.getAll())
          .where((role) => role.teamId.isEmpty)
          .toList();
      if (cached.isNotEmpty) return cached;
      throw Exception('Failed to fetch roles: $e');
    }
  }

  @override
  Future<RoleEntity?> getRoleById(String id) async {
    try {
      return await _remote.getById(id);
    } catch (e) {
      throw Exception('Failed to fetch role: $e');
    }
  }

  @override
  Future<RoleEntity> createRole(RoleEntity role) async {
    try {
      return await _remote.create(role);
    } catch (e) {
      throw Exception('Failed to create role: $e');
    }
  }

  @override
  Future<RoleEntity> updateRole(RoleEntity role) async {
    try {
      return await _remote.update(role.id ?? '', role);
    } catch (e) {
      throw Exception('Failed to update role: $e');
    }
  }

  @override
  Future<List<RoleEntity>> getAllRolesByTeamId(String teamId) async {
    try {
      final local = await _local.getAllByTeamId(teamId);
      if (local.isNotEmpty) {
        _remote.getAllByTeamId(teamId).catchError((_) => <RoleEntity>[]);
        return local;
      }
      return await _remote.getAllByTeamId(teamId);
    } catch (e) {
      final cached = await _local.getAllByTeamId(teamId);
      if (cached.isNotEmpty) return cached;
      throw Exception('Failed to fetch roles by team: $e');
    }
  }

  Future<void> refreshAll() async {
    await _remote.getAll();
  }
}
