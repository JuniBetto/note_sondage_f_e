import 'package:note_sondage/feature/team/domain/entities/permission_entity.dart';

// permission/data/mappers/permission_mapper.dart
class PermissionMapper {
  static PermissionEntity fromJson(Map<String, dynamic> json) {
    return PermissionEntity(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
    );
  }

  static Map<String, dynamic> toJson(PermissionEntity entity) {
    return {
      'id': entity.id,
      'code': entity.code,
      'description': entity.description,
    };
  }
}
