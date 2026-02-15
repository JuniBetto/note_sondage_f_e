import 'package:note_sondage/feature/team/domain/entities/role_entity.dart';

abstract class RoleRepository {
  Future<List<RoleEntity>> getAll();

  Future<List<RoleEntity>> getAllRolesByTeamId(String teamId);

  Future<RoleEntity?> getRoleById(String id);

  Future<RoleEntity> createRole(RoleEntity role);

  Future<RoleEntity> updateRole(RoleEntity role);

  Future<bool> deleteRole(String id);
}
