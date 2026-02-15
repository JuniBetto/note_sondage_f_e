import 'dart:convert';

import 'package:note_sondage/feature/team/domain/entities/team_member_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/user_status.dart';

class TeamMemberMapper {
  static TeamMemberEntity fromJson(Map<String, dynamic> json) {
    return TeamMemberEntity(
      id: json['id']?.toString(),
      userEmail: json['user_email']?.toString() ?? '',
      teamId: json['team_id']?.toString() ?? '',
      status: UserStatus.values.firstWhere(
        (e) => e.value == json['status'],
        orElse: () => UserStatus.pending,
      ),
      roleId: json['role_id']?.toString() ?? '',
      imageUrl: json['image_url']?.toString(),
      fileName: json['file_name']?.toString() ?? '',
      imageFile:
          json['image_file'], // imageFile e imageBytes non vengono dal server
      imageBytes: json['image_bytes'],
      initialName: json['initialname']?.toString() ?? '',
      // imageFile e imageBytes non vengono dal server
    );
  }

  static Map<String, dynamic> toJson(TeamMemberEntity member) {
    return {
      if (member.id != null) 'id': member.id,
      'user_email': member.userEmail,
      'team_id': member.teamId,
      'status': member.status.value,
      'role_id': member.roleId,
      if (member.imageUrl != null) 'image_url': member.imageUrl,
      if (member.imageFile != null) 'image_file': member.imageFile,
      if (member.imageBytes != null)
        'image_bytes': base64Encode(member.imageBytes!),
      'file_name': member.fileName ?? '',
      'initialName': '',
    };
  }

  static Map<String, dynamic> toJsonForUpdate(TeamMemberUpdateTeam entity) {
    return {
      'userId': entity.userId,
      'email': entity.email,
      'status': entity.status,
      'teamMemberId': entity.teamMemberId,
      'imageUrl': entity.imageUrl,
      'role': entity.role,
    };
  }

  static TeamMemberUpdateTeam fromJsonUpdate(Map<String, dynamic> json) {
    return TeamMemberUpdateTeam(
      userId: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      teamMemberId: json['teamMember_id']?.toString() ?? '',
      imageUrl: json['image_url']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
    );
  }
}
