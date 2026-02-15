import 'package:note_sondage/feature/team/domain/entities/role_entity.dart';

class RoleMapper {
  static RoleEntity fromJson(Map<String, dynamic> json) {
    final teamId = json['team_id']?.toString() ?? '';

    return RoleEntity(
      json['id']?.toString(),
      teamId: teamId,
      name: json['name']?.toString() ?? '',
      permissions: List<String>.from(json['permissions'] ?? []),
      description: json['description']?.toString(),
    );
  }

  static Map<String, dynamic> toJson(RoleEntity entity) {
    return {
      if (entity.id != null) 'id': entity.id,
      'team_id': entity.teamId,
      'name': entity.name,
      'permissions': entity.permissions,
      'description': entity.description,
    };
  }
}
