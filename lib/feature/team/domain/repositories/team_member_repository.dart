import 'dart:io';
import 'dart:typed_data';

import 'package:note_sondage/feature/team/domain/entities/team_invitation_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/team_member_entity.dart';

abstract class TeamMemberRepository {
  Future<List<TeamMemberEntity>> getAll();

  Future<List<TeamMemberEntity>> getAllByTeamId(String teamId);

  Future<TeamMemberEntity?> getById(String id);

  Future<TeamMemberEntity> create(TeamMemberEntity member);

  Future<TeamMemberEntity> update(TeamMemberEntity member);

  Future<bool> delete(String id);

  Future<bool> inviteMember(String teamId, String email, String roleId);

  Future<List<TeamInvitationEntity>> getPendingInvitations(String teamId);

  Future<void> cancelInvitation(String teamId, String invitationId);

  Future<TeamMemberEntity> uploadProfileImage({
    required String memberId,
    File? imageFile,
    Uint8List? imageBytes,
    String? fileName,
  });
}
