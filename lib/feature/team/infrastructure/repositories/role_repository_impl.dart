import 'package:note_sondage/feature/team/domain/entities/role_entity.dart';
import 'package:note_sondage/feature/team/domain/repositories/role_repository.dart';
import 'package:note_sondage/feature/team/infrastructure/data_source/data_source_remote/role_remote_data_source.dart';

class RoleRepositoryImpl implements RoleRepository {
  final RoleRemoteDataSource remoteDataSource;
  RoleRepositoryImpl(this.remoteDataSource);

  @override
  Future<bool> deleteRole(String id) async {
    try {
      await remoteDataSource.delete(id);
      return true;
    } catch (e) {
      throw Exception('Failed to delete role: $e');
    }
  }

  @override
  Future<List<RoleEntity>> getAll() async {
    try {
      final res = await remoteDataSource.getAll();
      return res;
    } catch (e) {
      throw Exception('Failed to fetch roles: $e');
    }
  }

  @override
  Future<RoleEntity?> getRoleById(String id) async {
    try {
      return await remoteDataSource.getById(id);
    } catch (e) {
      throw Exception('Failed to fetch role: $e');
    }
  }

  @override
  Future<RoleEntity> createRole(RoleEntity role) async {
    try {
      return await remoteDataSource.create(role);
    } catch (e) {
      throw Exception('Failed to create role: $e');
    }
  }

  @override
  Future<RoleEntity> updateRole(RoleEntity role) async {
    try {
      return await remoteDataSource.update(role.id ?? '', role);
    } catch (e) {
      throw Exception('Failed to update role: $e');
    }
  }

  @override
  Future<List<RoleEntity>> getAllRolesByTeamId(String teamId) async {
    try {
      return await remoteDataSource.getAllByTeamId(teamId);
    } catch (e) {
      throw Exception('Failed to fetch roles by team ID: $e');
    }
  }
}
