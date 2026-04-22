import 'dart:io';
import 'dart:typed_data';

import 'package:note_sondage/feature/team/domain/entities/team_invitation_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/team_member_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/user_status.dart';
import 'package:note_sondage/feature/team/domain/repositories/team_member_repository.dart';
import 'package:note_sondage/feature/team/domain/use_case/user/user_use_case.dart';

class TeamMemberUseCase {
  final TeamMemberRepository repository;
  final UserUseCase? userUseCase; // Opzionale per backward compatibility

  TeamMemberUseCase(this.repository, {this.userUseCase});

  Future<List<TeamMemberEntity>> getAllMembers() async {
    try {
      return await repository.getAll();
    } catch (e) {
      throw Exception('Failed to fetch team members: $e');
    }
  }

  Future<List<TeamMemberEntity>> getAllMembersByTeamId(String teamId) async {
    try {
      return await repository.getAllByTeamId(teamId);
    } catch (e) {
      throw Exception('Failed to fetch team members by team ID: $e');
    }
  }

  Future<TeamMemberEntity?> getMemberById(String id) async {
    try {
      return await repository.getById(id);
    } catch (e) {
      throw Exception('Failed to fetch team member: $e');
    }
  }

  Future<TeamMemberEntity> createMember(TeamMemberEntity member) async {
    try {
      return await repository.create(member);
    } catch (e) {
      throw Exception('Failed to create team member: $e');
    }
  }

  /// Crea un membro del team usando l'email.
  /// Se l'utente non esiste, viene creato con is_active = false.
  Future<TeamMemberEntity> createMemberByEmail({
    required String email,
    required String teamId,
    required String roleId,
    UserStatus status = UserStatus.pending,
  }) async {
    if (userUseCase == null) {
      throw Exception('UserUseCase is required for createMemberByEmail');
    }

    try {
      // 1. Trova o crea l'utente
      final user = await userUseCase!.getOrCreateUserByEmail(email);

      // 2. Crea il TeamMember con l'userId reale
      final member = TeamMemberEntity(
        id: null, // id sarà generato dal backend
        userEmail: user.email,
        teamId: teamId,
        status: status,
        roleId: roleId,
      );

      return await repository.create(member);
    } catch (e) {
      throw Exception('Failed to create team member by email: $e');
    }
  }

  Future<TeamMemberEntity> updateMember(TeamMemberEntity member) async {
    try {
      return await repository.update(member);
    } catch (e) {
      throw Exception('Failed to update team member: $e');
    }
  }

  Future<bool> deleteMember(String id) async {
    try {
      return await repository.delete(id);
    } catch (e) {
      throw Exception('Failed to delete team member: $e');
    }
  }

  Future<bool> inviteMember(String teamId, String email, String roleId) async {
    try {
      return await repository.inviteMember(teamId, email, roleId);
    } catch (e) {
      throw Exception('Failed to invite team member: $e');
    }
  }

  Future<List<TeamInvitationEntity>> getPendingInvitations(String teamId) async {
    try {
      return await repository.getPendingInvitations(teamId);
    } catch (e) {
      throw Exception('Failed to fetch invitations: $e');
    }
  }

  Future<void> cancelInvitation(String teamId, String invitationId) async {
    try {
      await repository.cancelInvitation(teamId, invitationId);
    } catch (e) {
      throw Exception('Failed to cancel invitation: $e');
    }
  }

  /// Uploads a profile image for a team member.
  /// If the member already has an image, it will be replaced.
  Future<TeamMemberEntity> uploadProfileImage({
    required String memberId,
    File? imageFile,
    Uint8List? imageBytes,
    String? fileName,
  }) async {
    try {
      return await repository.uploadProfileImage(
        memberId: memberId,
        imageFile: imageFile,
        imageBytes: imageBytes,
        fileName: fileName,
      );
    } catch (e) {
      throw Exception('Failed to upload profile image: $e');
    }
  }

  /// Crea un membro del team e carica l'immagine profilo se fornita.
  Future<TeamMemberEntity> createMemberWithImage({
    required String email,
    required String teamId,
    required String roleId,
    UserStatus status = UserStatus.pending,
    File? imageFile,
    Uint8List? imageBytes,
    String? fileName,
  }) async {
    // 1. Crea il membro
    final member = await createMemberByEmail(
      email: email,
      teamId: teamId,
      roleId: roleId,
      status: status,
    );

    // 2. Se c'è un'immagine, caricala
    if (imageFile != null || imageBytes != null) {
      if (member.id != null) {
        return await uploadProfileImage(
          memberId: member.id!,
          imageFile: imageFile,
          imageBytes: imageBytes,
          fileName: fileName,
        );
      }
    }

    return member;
  }
}
