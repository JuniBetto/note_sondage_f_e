import 'dart:io';
import 'dart:typed_data';

import 'package:note_sondage/feature/team/domain/entities/team_invitation_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/team_member_entity.dart';
import 'package:note_sondage/feature/team/domain/repositories/team_member_repository.dart';
import 'package:note_sondage/feature/team/infrastructure/data_source/data_source_local/team_member_local_data_source.dart';
import 'package:note_sondage/feature/team/infrastructure/data_source/data_source_remote/team_member_remote_data_source.dart';

class TeamMemberRepositoryImpl implements TeamMemberRepository {
  final TeamMemberLocalDataSource _local;
  final TeamMemberRemoteDataSource _remote;

  TeamMemberRepositoryImpl(this._local, this._remote);

  @override
  Future<bool> delete(String id) async {
    try {
      await _remote.delete(id);
      return true;
    } catch (e) {
      throw Exception('Failed to delete team member: $e');
    }
  }

  @override
  Future<List<TeamMemberEntity>> getAll() async {
    try {
      final local = await _local.getAll();
      if (local.isNotEmpty) {
        _remote.getAll().catchError((_) => <TeamMemberEntity>[]);
        return local;
      }
      return await _remote.getAll();
    } catch (e) {
      final cached = await _local.getAll();
      if (cached.isNotEmpty) return cached;
      throw Exception('Failed to fetch team members: $e');
    }
  }

  @override
  Future<List<TeamMemberEntity>> getAllByTeamId(String teamId) async {
    try {
      return await _remote.getAllByTeamId(teamId);
    } catch (e) {
      final cached = await _local.getAllByTeamId(teamId);
      if (cached.isNotEmpty) return cached;
      throw Exception('Failed to fetch team members by team ID: $e');
    }
  }

  @override
  Future<TeamMemberEntity?> getById(String id) async {
    try {
      return await _remote.getById(id);
    } catch (e) {
      throw Exception('Failed to fetch team member: $e');
    }
  }

  @override
  Future<TeamMemberEntity> create(TeamMemberEntity member) async {
    try {
      return await _remote.create(member);
    } catch (e) {
      throw Exception('Failed to create team member: $e');
    }
  }

  @override
  Future<TeamMemberEntity> update(TeamMemberEntity member) async {
    try {
      return await _remote.update(member.id?.toString() ?? '', member);
    } catch (e) {
      throw Exception('Failed to update team member: $e');
    }
  }

  @override
  Future<bool> inviteMember(String teamId, String email, String roleId) async {
    try {
      return await _remote.inviteMember(teamId, email, roleId);
    } catch (e) {
      throw Exception('Failed to invite team member: $e');
    }
  }

  @override
  Future<List<TeamInvitationEntity>> getPendingInvitations(String teamId) async {
    try {
      return await _remote.getPendingInvitations(teamId);
    } catch (e) {
      throw Exception('Failed to fetch invitations: $e');
    }
  }

  @override
  Future<void> cancelInvitation(String teamId, String invitationId) async {
    try {
      await _remote.cancelInvitation(teamId, invitationId);
    } catch (e) {
      throw Exception('Failed to cancel invitation: $e');
    }
  }

  @override
  Future<TeamMemberEntity> uploadProfileImage({
    required String memberId,
    File? imageFile,
    Uint8List? imageBytes,
    String? fileName,
  }) async {
    try {
      return await _remote.uploadProfileImage(
        memberId: memberId,
        imageFile: imageFile,
        imageBytes: imageBytes,
        fileName: fileName,
      );
    } catch (e) {
      throw Exception('Failed to upload profile image: $e');
    }
  }

  Future<void> refreshAll() async {
    await _remote.getAll();
  }
}
