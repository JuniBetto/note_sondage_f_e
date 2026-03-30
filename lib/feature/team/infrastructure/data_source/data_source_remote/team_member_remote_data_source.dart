import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:note_sondage/core/network/setup_dio.dart';
import 'package:note_sondage/feature/team/domain/entities/team_member_entity.dart';
import 'package:note_sondage/feature/team/domain/repositories/crud_service.dart';
import 'package:note_sondage/feature/team/infrastructure/data/team_member_mapper.dart';
import 'package:note_sondage/feature/team/infrastructure/data_source/data_source_local/team_member_local_data_source.dart';

class TeamMemberRemoteDataSource extends CrudService<TeamMemberEntity> {
  final TeamMemberLocalDataSource localDataSource;

  TeamMemberRemoteDataSource(this.localDataSource)
    : super(DioClient().dio, '/team-members');

  @override
  Future<TeamMemberEntity> create(TeamMemberEntity item) async {
    try {
      final itemwithoutImage = item.copyWith(
        imageUrl: null,
        imageFile: null,
        imageBytes: null,
        fileName: null,
      );
      var updatedPreTeamMember;
      final response = await DioClient().dio.post(
        '$endpoint/add',
        data: TeamMemberMapper.toJson(itemwithoutImage),
      );
      final data = response.data;
      final preTeamMember = TeamMemberMapper.fromJson(
        data as Map<String, dynamic>,
      );
      updatedPreTeamMember = preTeamMember;

      if (preTeamMember.id != null &&
          (item.imageBytes != null || item.imageFile != null)) {
        final response = await DioClient().dio.post(
          '$endpoint/${preTeamMember.id}/profile-image',
          data: FormData.fromMap({
            'file': item.imageFile != null
                ? await MultipartFile.fromFile(
                    item.imageFile!.path,
                    filename: item.imageFile!.path.split('/').last,
                  )
                : MultipartFile.fromBytes(
                    item.imageBytes!,
                    filename: item.fileName ?? 'profile_image.png',
                  ),
          }),
          options: Options(
            contentType: 'multipart/form-data',
            receiveTimeout: const Duration(minutes: 5), // 5 minuti
            sendTimeout: const Duration(minutes: 5),
          ),
        );

        final updatedData = response.data;
        final newTeamMember = TeamMemberMapper.fromJson(
          updatedData as Map<String, dynamic>,
        );
        updatedPreTeamMember = preTeamMember.copyWith(
          imageUrl: newTeamMember.imageUrl,
          fileName: newTeamMember.fileName,
        );
      }

      return updatedPreTeamMember;
    } catch (e) {
      throw Exception('Failed to create team member: $e');
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await DioClient().dio.delete('$endpoint/delete/$id');
    } catch (e) {
      throw Exception('Failed to delete team member: $e');
    }
  }

  @override
  Future<List<TeamMemberEntity>> getAll() async {
    try {
      final response = await DioClient().dio.get('$endpoint/all');

      if (response.data == null) {
        return [];
      }

      final data = response.data as List;
      final members = data
          .where((e) => e != null)
          .map((e) => TeamMemberMapper.fromJson(e as Map<String, dynamic>))
          .toList();
      await localDataSource.saveAll(members);
      return members;
    } catch (e) {
      throw Exception('Failed to fetch team members: $e');
    }
  }

  Future<List<TeamMemberEntity>> getAllByTeamId(String teamId) async {
    try {
      final response = await DioClient().dio.get('$endpoint/team/$teamId');

      if (response.data == null) {
        return [];
      }

      final data = response.data as List;
      final members = data
          .where((e) => e != null)
          .map((e) => TeamMemberMapper.fromJson(e as Map<String, dynamic>))
          .toList();
      await localDataSource.saveAll(members);
      return members;
    } catch (e) {
      throw Exception('Failed to fetch team members by team ID: $e');
    }
  }

  @override
  Future<TeamMemberEntity> getById(String id) async {
    try {
      final response = await DioClient().dio.get('$endpoint/$id');
      return TeamMemberMapper.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to fetch team member: $e');
    }
  }

  @override
  Future<TeamMemberEntity> update(String id, TeamMemberEntity item) async {
    try {
      final newId = id.isEmpty ? item.id?.toString() : id;
      final jsonData = TeamMemberMapper.toJson(item);
      final response = await DioClient().dio.put(
        '$endpoint/update/$newId',
        data: jsonData,
      );
      return TeamMemberMapper.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update team member: $e');
    }
  }

  Future<bool> inviteMember(String teamId, String email, String roleId) async {
    try {
      await DioClient().dio.post(
        '$endpoint/invite',
        data: {'team_id': teamId, 'email': email, 'role_id': roleId},
      );
      return true;
    } catch (e) {
      throw Exception('Failed to invite team member: $e');
    }
  }

  /// Uploads a profile image for a team member.
  /// Endpoint: POST /team-members/{member_id}/profile-image
  ///
  /// [memberId] - The ID of the team member
  /// [imageFile] - The image file (for mobile)
  /// [imageBytes] - The image bytes (for web)
  /// [fileName] - The file name (required when using imageBytes)
  Future<TeamMemberEntity> uploadProfileImage({
    required String memberId,
    File? imageFile,
    Uint8List? imageBytes,
    String? fileName,
  }) async {
    try {
      if (imageFile == null && imageBytes == null) {
        throw Exception('Either imageFile or imageBytes must be provided');
      }

      late MultipartFile multipartFile;

      if (imageFile != null) {
        // Mobile: use file path
        multipartFile = await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
        );
      } else {
        // Web: use bytes
        multipartFile = MultipartFile.fromBytes(
          imageBytes!,
          filename: fileName ?? 'profile_image.png',
        );
      }

      final formData = FormData.fromMap({'file': multipartFile});

      final response = await DioClient().dio.post(
        '$endpoint/$memberId/profile-image',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      return TeamMemberMapper.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to upload profile image: $e');
    }
  }
}
