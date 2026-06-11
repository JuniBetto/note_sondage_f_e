import 'package:note_sondage/feature/team/domain/entities/role_entity.dart';
import 'package:note_sondage/feature/team/domain/repositories/role_repository.dart';

class RoleUseCase {
  final RoleRepository repository;
  RoleUseCase(this.repository);

  Future<List<RoleEntity>> getAllRoles() async {
    try {
      final roles = await repository.getAll();
      return roles;
    } catch (e) {
      throw Exception('Failed to fetch roles: $e');
    }
  }

  Future<List<RoleEntity>> getAllRolesByTeamId(String teamId) async {
    try {
      final roles = await repository.getAllRolesByTeamId(teamId);
      return roles;
    } catch (e) {
      throw Exception('Failed to fetch roles by team ID: $e');
    }
  }

  Future<RoleEntity?> getRoleById(String id) async {
    return await repository.getRoleById(id);
  }

  Future<RoleEntity> createRole(RoleEntity entity) async {
    return await repository.createRole(entity);
  }

  Future<RoleEntity> updateRole(RoleEntity entity) async {
    return await repository.updateRole(entity);
  }

  Future<bool> deleteRole(String id) async {
    return await repository.deleteRole(id);
  }
}
