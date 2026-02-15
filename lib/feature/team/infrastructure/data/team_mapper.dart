import 'dart:ui';

import 'package:note_sondage/domain/entities/user_mapper.dart';
import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';
import 'package:note_sondage/feature/team/infrastructure/data/team_member_mapper.dart';

class TeamMapper {
  static TeamEntity fromJson(Map<String, dynamic> json) {
    // Gestisce createdAt null
    DateTime? createdAt;
    if (json['createdAt'] != null) {
      try {
        createdAt = DateTime.parse(json['createdAt'] as String);
      } catch (_) {
        createdAt = null;
      }
    }

    return TeamEntity(
      json['id']?.toString(),
      json['color']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      createdByUserId: json['createdByUserId']?.toString() ?? '',
      createdAt: createdAt,
    );
  }

  static Map<String, dynamic> toJson(TeamEntity entity) {
    return {
      'id': entity.id,
      if (entity.color != null) 'color': entity.color,
      'name': entity.name,
      'description': entity.description,
      'createdByUserId': entity.createdByUserId,
      'createdAt': entity.createdAt.toIso8601String(),
    };
  }

  static Map<String, dynamic> toJsonForUpdate(TeamUpdate entity) {
    return {
      'name': entity.name,
      'description': entity.description,
      'color': entity.color,
      'list_member': entity.listMember
          .map((member) => TeamMemberMapper.toJsonForUpdate(member))
          .toList(),
    };
  }

  static TeamUpdate fromJsonForUpdate(Map<String, dynamic> json) {
    return TeamUpdate(
      json['is_deleted'] as bool?,
      id: json['id']?.toString(),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      createdByUserId: json['created_by_user_id']?.toString() ?? '',
      color: json['color']?.toString() ?? '',
      listMember:
          (json['list_member'] as List<dynamic>?)
              ?.map(
                (memberJson) => TeamMemberMapper.fromJsonUpdate(
                  memberJson as Map<String, dynamic>,
                ),
              )
              .toList() ??
          [],
    );
  }
}
