import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';

class RoleEntity {
  final String? id;
  final String teamId;
  final String name;
  final List<String> permissions;
  final String? description;

  RoleEntity(
    this.id, {
    required this.teamId,
    required this.name,
    required this.permissions,
    this.description,
  });

  RoleEntity copyWith({
    String? id,
    String? teamId,
    String? name,
    List<String>? permissions,
    String? description,
  }) {
    return RoleEntity(
      id ?? this.id,
      teamId: teamId ?? this.teamId,
      name: name ?? this.name,
      permissions: permissions ?? this.permissions,
      description: description ?? this.description,
    );
  }
}
