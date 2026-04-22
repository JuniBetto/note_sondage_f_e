import 'package:note_sondage/feature/team/domain/entities/invite_team_member_request_entity.dart';

class InviteTeamMemberRequestMapper {
  static Map<String, dynamic> toJson(InviteTeamMemberRequestEntity entity) {
    return {'email': entity.email, 'proposedRole': entity.roleId};
  }

  static InviteTeamMemberRequestEntity fromJson(Map<String, dynamic> json) {
    return InviteTeamMemberRequestEntity(
      email: json['email']?.toString() ?? '',
      roleId: json['roleId']?.toString() ?? '',
    );
  }
}
