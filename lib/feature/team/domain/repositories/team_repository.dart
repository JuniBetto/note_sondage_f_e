import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/planning_worker_type_entity.dart';

abstract class TeamRepository {
  Future<List<TeamEntity>> getAll();

  Future<List<TeamEntity>> getLocalOnly();

  Future<List<TeamEntity>> getAllByUserId(String userId);

  Future<TeamEntity?> getById(String id);

  Future<TeamEntity> create(TeamEntity team);

  Future<TeamEntity> createByUser(TeamEntity team, String userId);

  Future<TeamUpdate> update(TeamUpdate team);

  Future<List<PlanningWorkerTypeEntity>> updatePlanningWorkerTypes(
    String teamId,
    List<PlanningWorkerTypeEntity> workerTypes,
  );

  Future<bool> delete(String id);
}
