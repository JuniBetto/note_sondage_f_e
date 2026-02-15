import 'dart:io';
import 'dart:typed_data';

import 'package:note_sondage/feature/team/domain/entities/team_member_entity.dart';

abstract class TeamMemberRepository {
  @override
  Future<List<TeamMemberEntity>> getAll();

  @override
  Future<List<TeamMemberEntity>> getAllByTeamId(String teamId);

  @override
  Future<TeamMemberEntity?> getById(String id);

  @override
  Future<TeamMemberEntity> create(TeamMemberEntity member);

  @override
  Future<TeamMemberEntity> update(TeamMemberEntity member);

  @override
  Future<bool> delete(String id);

  @override
  Future<bool> inviteMember(String teamId, String email, String roleId);

  /// Uploads a profile image for a team member.
  /// Returns the updated TeamMemberEntity with the new image URL.
  Future<TeamMemberEntity> uploadProfileImage({
    required String memberId,
    File? imageFile,
    Uint8List? imageBytes,
    String? fileName,
  });
}
