import 'package:note_sondage/feature/team/domain/entities/role_entity.dart';

class RoleMapper {
  static RoleEntity fromJson(Map<String, dynamic> json) {
    final permissions =
        (json['permissions'] as List?)
            ?.whereType<dynamic>()
            .map((item) => item.toString())
            .toList() ??
        const <String>[];

    return RoleEntity(
      json['code']?.toString() ?? json['id']?.toString(),
      teamId: json['teamId']?.toString() ?? '',
      name: json['name']?.toString() ?? json['code']?.toString() ?? '',
      permissions: permissions,
      description: json['description']?.toString(),
    );
  }

  static Map<String, dynamic> toJson(RoleEntity entity) {
    return {
      'name': entity.name,
      'description': entity.description,
      'permissions': entity.permissions,
    };
  }
}
