import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';
import 'package:note_sondage/feature/team/infrastructure/data/invite_team_member_request_mapper.dart';

class TeamMapper {
  static TeamEntity fromJson(Map<String, dynamic> json) {
    DateTime? createdAt;
    if (json['createdAt'] != null) {
      try {
        createdAt = DateTime.parse(json['createdAt'] as String);
      } catch (_) {
        createdAt = null;
      }
    }

    // Spring returns "ownerId", Python returned "createdByUserId" — handle both
    final createdByUserId =
        (json['ownerId'] ?? json['createdByUserId'])?.toString() ?? '';

    return TeamEntity(
      json['id']?.toString(),
      json['color']?.toString() ?? '',
      null, // pendingInvitations is not returned by the API
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      createdByUserId: createdByUserId,
      createdAt: createdAt,
    );
  }

  /// Serializes a [TeamEntity] for the POST /api/aggregate/teams endpoint.
  static Map<String, dynamic> toJson(TeamEntity entity) {
    final name = entity.name;
    final slug = name.toLowerCase().replaceAll(RegExp(r'\s+'), '-');
    return {
      'name': name,
      'slug': slug,
      'description': entity.description,
      if (entity.color != null && entity.color!.isNotEmpty) 'color': entity.color,
      'organisationId': null,
      if (entity.pendingInvitations != null &&
          entity.pendingInvitations!.isNotEmpty)
        'members': entity.pendingInvitations!
            .map(InviteTeamMemberRequestMapper.toJson)
            .toList(),
    };
  }

  static Map<String, dynamic> toJsonForUpdate(TeamUpdate entity) {
    return {
      'name': entity.name,
      'description': entity.description,
      if (entity.color != null && entity.color!.isNotEmpty) 'color': entity.color,
    };
  }

  static TeamUpdate fromJsonForUpdate(Map<String, dynamic> json) {
    return TeamUpdate(
      json['isActive'] != null ? !(json['isActive'] as bool) : false,
      id: json['id']?.toString(),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      createdByUserId:
          (json['ownerId'] ?? json['created_by_user_id'])?.toString() ?? '',
      color: json['color']?.toString() ?? '',
      listMember: [],
    );
  }
}
