import 'dart:io';
import 'dart:typed_data';

import 'package:note_sondage/core/network/setup_dio.dart';
import 'package:note_sondage/feature/team/domain/entities/team_invitation_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/team_member_entity.dart';
import 'package:note_sondage/feature/team/domain/repositories/crud_service.dart';
import 'package:note_sondage/feature/team/infrastructure/data/team_member_mapper.dart';
import 'package:note_sondage/feature/team/infrastructure/data_source/data_source_local/team_member_local_data_source.dart';

class TeamMemberRemoteDataSource extends CrudService<TeamMemberEntity> {
  final TeamMemberLocalDataSource localDataSource;

  TeamMemberRemoteDataSource(this.localDataSource)
    : super(DioClient().dio, '/api/aggregate/teams');

  // POST /api/aggregate/teams/{teamId}/invitations
  Future<bool> inviteMember(String teamId, String email, String roleId) async {
    try {
      await DioClient().dio.post(
        '$endpoint/$teamId/invitations',
        data: {'email': email, 'proposedRole': roleId},
      );
      return true;
    } catch (e) {
      throw Exception('Failed to invite team member: $e');
    }
  }

  // DELETE /api/aggregate/teams/{teamId}/members/{memberId}
  Future<void> deleteFromTeam(String teamId, String memberId) async {
    try {
      await DioClient().dio.delete('$endpoint/$teamId/members/$memberId');
    } catch (e) {
      throw Exception('Failed to remove team member: $e');
    }
  }

  // PATCH /api/aggregate/teams/{teamId}/members/{memberId}/role?role={role}
  Future<TeamMemberEntity> updateMemberRole(
    String teamId,
    String memberId,
    String role,
  ) async {
    try {
      final response = await DioClient().dio.patch(
        '$endpoint/$teamId/members/$memberId/role',
        queryParameters: {'role': role},
      );
      final memberJson = Map<String, dynamic>.from(response.data as Map<String, dynamic>);
      memberJson['team_id'] ??= teamId;
      return TeamMemberMapper.fromJson(memberJson);
    } catch (e) {
      throw Exception('Failed to update member role: $e');
    }
  }

  @override
  Future<TeamMemberEntity> create(TeamMemberEntity item) async {
    try {
      final response = await DioClient().dio.post(
        '$endpoint/${item.teamId}/invitations',
        data: {'email': item.userEmail, 'proposedRole': item.roleId},
      );
      return TeamMemberMapper.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create team member: $e');
    }
  }

  @override
  Future<void> delete(String id) async {
    // id format: "teamId/memberId"
    final parts = id.split('/');
    if (parts.length < 2) {
      throw Exception('delete expects id in format teamId/memberId');
    }
    await deleteFromTeam(parts[0], parts[1]);
  }

  @override
  Future<List<TeamMemberEntity>> getAll() async {
    return [];
  }

  Future<List<TeamMemberEntity>> getAllByTeamId(String teamId) async {
    try {
      final response = await DioClient().dio.get('$endpoint/$teamId/dashboard');
      final data = response.data as Map<String, dynamic>;
      final teamData = data['team'] as Map<String, dynamic>? ?? {};
      final membersJson = teamData['members'] as List<dynamic>? ?? [];
      final members = membersJson
          .where((e) => e != null)
          .map((e) {
            final memberJson = Map<String, dynamic>.from(e as Map<String, dynamic>);
            // Inject team_id if the API doesn't include it per-member
            memberJson['team_id'] ??= teamId;
            return TeamMemberMapper.fromJson(memberJson);
          })
          .toList();
      await localDataSource.saveAll(members);
      return members;
    } catch (e) {
      throw Exception('Failed to fetch team members by team ID: $e');
    }
  }

  @override
  Future<TeamMemberEntity> getById(String id) async {
    throw UnimplementedError('Use getAllByTeamId instead');
  }

  @override
  Future<TeamMemberEntity> update(String id, TeamMemberEntity item) async {
    return updateMemberRole(item.teamId, id, item.roleId);
  }

  // GET /api/aggregate/teams/{teamId}/invitations
  Future<List<TeamInvitationEntity>> getPendingInvitations(String teamId) async {
    try {
      final response = await DioClient().dio.get('$endpoint/$teamId/invitations');
      final list = response.data as List<dynamic>? ?? [];
      return list.map((e) {
        final j = e as Map<String, dynamic>;
        return TeamInvitationEntity(
          id: j['id']?.toString() ?? '',
          teamId: teamId,
          invitedEmail: j['invitedEmail']?.toString() ?? '',
          proposedRole: j['proposedRole']?.toString() ?? '',
          status: j['status']?.toString() ?? 'PENDING',
          expiresAt: j['expiresAt'] != null ? DateTime.tryParse(j['expiresAt'].toString()) : null,
          createdAt: j['createdAt'] != null ? DateTime.tryParse(j['createdAt'].toString()) : null,
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch pending invitations: $e');
    }
  }

  // DELETE /api/aggregate/teams/{teamId}/invitations/{invitationId}
  Future<void> cancelInvitation(String teamId, String invitationId) async {
    try {
      await DioClient().dio.delete('$endpoint/$teamId/invitations/$invitationId');
    } catch (e) {
      throw Exception('Failed to cancel invitation: $e');
    }
  }

  Future<TeamMemberEntity> uploadProfileImage({
    required String memberId,
    File? imageFile,
    Uint8List? imageBytes,
    String? fileName,
  }) async {
    throw UnimplementedError(
      'Profile image upload is not supported by the Spring aggregator',
    );
  }
}
