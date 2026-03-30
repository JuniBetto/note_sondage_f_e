import 'package:note_sondage/core/network/setup_dio.dart';
import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';
import 'package:note_sondage/feature/team/domain/repositories/crud_service.dart';
import 'package:note_sondage/feature/team/infrastructure/data/team_mapper.dart';
import 'package:note_sondage/feature/team/infrastructure/data_source/data_source_local/team_local_data_source.dart';

class TeamRemoteDataSource extends CrudService<TeamEntity> {
  final TeamLocalDataSource localDataSource;

  TeamRemoteDataSource(this.localDataSource) : super(DioClient().dio, '/teams');

  @override
  Future<TeamEntity> create(TeamEntity item) async {
    try {
      final response = await DioClient().dio.post(
        '$endpoint/create',
        data: TeamMapper.toJson(item),
      );
      final data = response.data;
      return TeamMapper.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create team: $e');
    }
  }

  Future<TeamEntity> createByUser(TeamEntity item, String userId) async {
    try {
      final response = await DioClient().dio.post(
        '$endpoint/create/$userId',
        data: TeamMapper.toJson(item),
      );
      final data = response.data;
      return TeamMapper.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create team: $e');
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await DioClient().dio.delete('$endpoint/delete/$id');
    } catch (e) {
      throw Exception('Failed to delete team: $e');
    }
  }

  @override
  Future<List<TeamEntity>> getAll() async {
    try {
      final response = await DioClient().dio.get('$endpoint/all');

      if (response.data == null) {
        return [];
      }

      final data = response.data as List;
      final teams = data
          .where((e) => e != null)
          .map((e) => TeamMapper.fromJson(e as Map<String, dynamic>))
          .toList();
      await localDataSource.saveAll(teams);
      return teams;
    } catch (e) {
      throw Exception('Failed to fetch teams: $e');
    }
  }

  Future<List<TeamEntity>> getAllByUserId(String userId) async {
    try {
      final response = await DioClient().dio.get(
        '$endpoint/all_by_user/$userId',
      );

      if (response.data == null) {
        return [];
      }

      final data = response.data as List;
      final teams = data
          .where((e) => e != null)
          .map((e) => TeamMapper.fromJson(e as Map<String, dynamic>))
          .toList();
      await localDataSource.saveAll(teams);
      return teams;
    } catch (e) {
      throw Exception('Failed to fetch teams by user ID: $e');
    }
  }

  @override
  Future<TeamEntity> getById(String id) async {
    try {
      final response = await DioClient().dio.get('$endpoint/$id');
      return TeamMapper.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to fetch team: $e');
    }
  }

  @override
  Future<TeamEntity> update(String id, TeamEntity item) async {
    try {
      final newId = id.isEmpty ? item.id : id;
      final jsonData = TeamMapper.toJson(item);
      final response = await DioClient().dio.put(
        '$endpoint/update/$newId',
        data: jsonData,
      );
      return TeamMapper.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update team: $e');
    }
  }

  Future<TeamUpdate> updateTeamUpdater(String id, TeamUpdate item) async {
    try {
      final newId = id.isEmpty ? item.id : id;
      final jsonData = TeamMapper.toJsonForUpdate(item);
      final response = await DioClient().dio.put(
        '$endpoint/update/$newId',
        data: jsonData,
      );
      return TeamMapper.fromJsonForUpdate(
        response.data as Map<String, dynamic>,
      );
    } catch (e) {
      throw Exception('Failed to update team: $e');
    }
  }

  Future<List<TeamEntity>> getAllByTeamId(String teamId) async {
    try {
      final response = await DioClient().dio.get('$endpoint/team/$teamId');

      if (response.data == null) {
        return [];
      }

      final data = response.data as List;
      return data
          .where((e) => e != null)
          .map((e) => TeamMapper.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch teams by user ID: $e');
    }
  }
}
