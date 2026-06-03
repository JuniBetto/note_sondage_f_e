import 'package:flutter_test/flutter_test.dart';
import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';
import 'package:note_sondage/feature/team/domain/repositories/team_repository.dart';
import 'package:note_sondage/feature/team/domain/use_case/team/team_use_case.dart';

import '../../../../support/team_fixtures.dart';

class _FakeTeamRepository implements TeamRepository {
  Future<List<TeamEntity>> Function()? getAllHandler;
  Future<List<TeamEntity>> Function()? getLocalOnlyHandler;
  Future<List<TeamEntity>> Function(String userId)? getAllByUserIdHandler;
  Future<TeamEntity?> Function(String id)? getByIdHandler;
  Future<TeamEntity> Function(TeamEntity team)? createHandler;
  Future<TeamEntity> Function(TeamEntity team, String userId)?
  createByUserHandler;
  Future<TeamUpdate> Function(TeamUpdate team)? updateHandler;
  Future<bool> Function(String id)? deleteHandler;

  int getAllCalls = 0;
  int getLocalOnlyCalls = 0;
  final getAllByUserIdCalls = <String>[];
  final createByUserCalls = <({TeamEntity team, String userId})>[];

  @override
  Future<TeamEntity> create(TeamEntity team) =>
      createHandler?.call(team) ?? Future.value(team);

  @override
  Future<TeamEntity> createByUser(TeamEntity team, String userId) {
    createByUserCalls.add((team: team, userId: userId));
    return createByUserHandler?.call(team, userId) ?? Future.value(team);
  }

  @override
  Future<bool> delete(String id) =>
      deleteHandler?.call(id) ?? Future.value(true);

  @override
  Future<List<TeamEntity>> getAll() {
    getAllCalls++;
    return getAllHandler?.call() ?? Future.value(const <TeamEntity>[]);
  }

  @override
  Future<List<TeamEntity>> getAllByUserId(String userId) {
    getAllByUserIdCalls.add(userId);
    return getAllByUserIdHandler?.call(userId) ??
        Future.value(const <TeamEntity>[]);
  }

  @override
  Future<TeamEntity?> getById(String id) =>
      getByIdHandler?.call(id) ?? Future.value(null);

  @override
  Future<List<TeamEntity>> getLocalOnly() {
    getLocalOnlyCalls++;
    return getLocalOnlyHandler?.call() ?? Future.value(const <TeamEntity>[]);
  }

  @override
  Future<TeamUpdate> update(TeamUpdate team) =>
      updateHandler?.call(team) ?? Future.value(team);
}

void main() {
  late _FakeTeamRepository repository;
  late TeamUseCase useCase;

  setUp(() {
    repository = _FakeTeamRepository();
    useCase = TeamUseCase(repository);
  });

  group('TeamUseCase', () {
    test('getAllTeams returns repository teams', () async {
      final teams = [buildTeam(), buildTeam(id: 'team-2', name: 'Design')];
      repository.getAllHandler = () async => teams;

      final result = await useCase.getAllTeams();

      expect(result, same(teams));
      expect(repository.getAllCalls, 1);
    });

    test('getAllTeamsByUserId wraps repository errors', () async {
      repository.getAllByUserIdHandler = (_) =>
          Future<List<TeamEntity>>.error(Exception('backend down'));

      expect(
        useCase.getAllTeamsByUserId('user-42'),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('Failed to fetch teams by user ID'),
          ),
        ),
      );
    });

    test('createTeamByUser delegates team and user id', () async {
      final team = buildTeam();
      repository.createByUserHandler = (team, _) async => team;

      final result = await useCase.createTeamByUser(team, 'user-42');

      expect(result, same(team));
      expect(repository.createByUserCalls, hasLength(1));
      expect(repository.createByUserCalls.single.team, same(team));
      expect(repository.createByUserCalls.single.userId, 'user-42');
    });

    test('getLocalTeams returns repository local cache', () async {
      final localTeams = [buildTeam(id: 'local-team')];
      repository.getLocalOnlyHandler = () async => localTeams;

      final result = await useCase.getLocalTeams();

      expect(result, same(localTeams));
      expect(repository.getLocalOnlyCalls, 1);
    });
  });
}
