import 'package:note_sondage/core/network/setup_dio.dart';
import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';
import 'package:note_sondage/feature/team/domain/repositories/crud_service.dart';
import 'package:note_sondage/feature/team/infrastructure/data/team_mapper.dart';
import 'package:note_sondage/feature/team/infrastructure/data_source/data_source_local/team_local_data_source.dart';

class TeamRemoteDataSource extends CrudService<TeamEntity> {
  final TeamLocalDataSource localDataSource;

  TeamRemoteDataSource(this.localDataSource)
      : super(DioClient().dio, '/api/aggregate/teams');

  // CREATE
  @override
  Future<TeamEntity> create(TeamEntity item) async {
    try {
      final response = await DioClient().dio.post(
        endpoint,
        data: TeamMapper.toJson(item),
      );
      return TeamMapper.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create team: $e');
    }
  }

  /// Spring identifies the owner via JWT — userId param ignored.
  Future<TeamEntity> createByUser(TeamEntity item, String userId) => create(item);

  // DELETE  /api/aggregate/teams/{id}
  @override
  Future<void> delete(String id) async {
    try {
      await DioClient().dio.delete('$endpoint/$id');
    } catch (e) {
      throw Exception('Failed to delete team: $e');
    }
  }

  // GET ALL  /api/aggregate/teams/my/dashboard
  // Response: List<TeamDashboardResponse> each with a "team" field (TeamDto)
  @override
  Future<List<TeamEntity>> getAll() async {
    try {
      final response = await DioClient().dio.get('$endpoint/my/dashboard');
      if (response.data == null) return [];
      final data = response.data as List;
      final teams = data
          .where((e) => e != null && e['team'] != null)
          .map((e) => TeamMapper.fromJson(e['team'] as Map<String, dynamic>))
          .toList();
      await localDataSource.saveAll(teams);
      return teams;
    } catch (e) {
      throw Exception('Failed to fetch teams: $e');
    }
  }

  /// Spring filters by JWT — userId param ignored.
  Future<List<TeamEntity>> getAllByUserId(String userId) => getAll();

  // GET BY ID  /api/aggregate/teams/{id}/dashboard
  // Response: TeamDashboardResponse  with "team" field
  @override
  Future<TeamEntity> getById(String id) async {
    try {
      final response = await DioClient().dio.get('$endpoint/$id/dashboard');
      final data = response.data as Map<String, dynamic>;
      final teamData =
          data.containsKey('team') ? data['team'] as Map<String, dynamic> : data;
      return TeamMapper.fromJson(teamData);
    } catch (e) {
      throw Exception('Failed to fetch team: $e');
    }
  }

  // UPDATE  PUT /api/aggregate/teams/{id}  body: { name, description }
  @override
  Future<TeamEntity> update(String id, TeamEntity item) async {
    try {
      final response = await DioClient().dio.put(
        '$endpoint/$id',
        data: {'name': item.name, 'description': item.description},
      );
      return TeamMapper.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update team: $e');
    }
  }

  Future<TeamUpdate> updateTeamUpdater(String id, TeamUpdate item) async {
    try {
      final effectiveId = id.isEmpty ? item.id ?? '' : id;
      final response = await DioClient().dio.put(
        '$endpoint/$effectiveId',
        data: TeamMapper.toJsonForUpdate(item),
      );
      return TeamMapper.fromJsonForUpdate(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update team: $e');
    }
  }

  /// Returns the single team as a one-element list (backwards compat).
  Future<List<TeamEntity>> getAllByTeamId(String teamId) async {
    final team = await getById(teamId);
    return [team];
  }
}
