import 'package:note_sondage/feature/team/domain/entities/permission_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/role_entity.dart';

class RolePermissionEntity {
  final RoleEntity role;
  final PermissionEntity permissions;

  RolePermissionEntity({required this.role, required this.permissions});
}
