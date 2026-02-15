import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';

abstract class TeamRepository {
  Future<List<TeamEntity>> getAll();

  Future<List<TeamEntity>> getAllByUserId(String userId);

  Future<TeamEntity?> getById(String id);

  Future<TeamEntity> create(TeamEntity team);

  Future<TeamEntity> createByUser(TeamEntity team, String userId);

  Future<TeamUpdate> update(TeamUpdate team);

  Future<bool> delete(String id);
}
