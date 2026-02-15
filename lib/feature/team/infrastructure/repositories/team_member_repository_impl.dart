import 'dart:io';
import 'dart:typed_data';

import 'package:note_sondage/feature/team/domain/entities/team_member_entity.dart';
import 'package:note_sondage/feature/team/domain/repositories/team_member_repository.dart';
import 'package:note_sondage/feature/team/infrastructure/data_source/team_member_remote_data_source.dart';

class TeamMemberRepositoryImpl implements TeamMemberRepository {
  final TeamMemberRemoteDataSource remoteDataSource;
  TeamMemberRepositoryImpl(this.remoteDataSource);

  @override
  Future<bool> delete(String id) async {
    try {
      await remoteDataSource.delete(id);
      return true;
    } catch (e) {
      throw Exception('Failed to delete team member: $e');
    }
  }

  @override
  Future<List<TeamMemberEntity>> getAll() async {
    try {
      return await remoteDataSource.getAll();
    } catch (e) {
      throw Exception('Failed to fetch team members: $e');
    }
  }

  @override
  Future<List<TeamMemberEntity>> getAllByTeamId(String teamId) async {
    try {
      return await remoteDataSource.getAllByTeamId(teamId);
    } catch (e) {
      throw Exception('Failed to fetch team members by team ID: $e');
    }
  }

  @override
  Future<TeamMemberEntity?> getById(String id) async {
    try {
      return await remoteDataSource.getById(id);
    } catch (e) {
      throw Exception('Failed to fetch team member: $e');
    }
  }

  @override
  Future<TeamMemberEntity> create(TeamMemberEntity member) async {
    try {
      return await remoteDataSource.create(member);
    } catch (e) {
      throw Exception('Failed to create team member: $e');
    }
  }

  @override
  Future<TeamMemberEntity> update(TeamMemberEntity member) async {
    try {
      return await remoteDataSource.update(member.id?.toString() ?? '', member);
    } catch (e) {
      throw Exception('Failed to update team member: $e');
    }
  }

  @override
  Future<bool> inviteMember(String teamId, String email, String roleId) async {
    try {
      return await remoteDataSource.inviteMember(teamId, email, roleId);
    } catch (e) {
      throw Exception('Failed to invite team member: $e');
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
      return await remoteDataSource.uploadProfileImage(
        memberId: memberId,
        imageFile: imageFile,
        imageBytes: imageBytes,
        fileName: fileName,
      );
    } catch (e) {
      throw Exception('Failed to upload profile image: $e');
    }
  }
}
