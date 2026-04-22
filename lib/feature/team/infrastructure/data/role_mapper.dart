import 'package:note_sondage/feature/team/domain/entities/role_entity.dart';

class RoleMapper {
  /// Parses a Spring TeamRoleDto: {id, code, name, priority}
  /// The role `code` (e.g. "MEMBER") is used as the identifier sent to the API.
  static RoleEntity fromJson(Map<String, dynamic> json) {
    return RoleEntity(
      json['code']?.toString() ?? json['id']?.toString(),
      teamId: '', // Roles are global in Spring, not team-scoped
      name: json['name']?.toString() ?? json['code']?.toString() ?? '',
      permissions: [],
      description: null,
    );
  }

  static Map<String, dynamic> toJson(RoleEntity entity) {
    return {if (entity.id != null) 'code': entity.id, 'name': entity.name};
  }
}
