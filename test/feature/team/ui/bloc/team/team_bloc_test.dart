import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';
import 'package:note_sondage/feature/team/domain/repositories/team_repository.dart';
import 'package:note_sondage/feature/team/domain/use_case/team/team_use_case.dart';
import 'package:note_sondage/feature/team/infrastructure/data_source/data_source_local/team_local_data_source.dart';
import 'package:note_sondage/feature/team/ui/bloc/team/team_bloc.dart';

import '../../../../../support/team_fixtures.dart';

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
  final createByUserCalls = <({TeamEntity team, String userId})>[];
  final updateCalls = <TeamUpdate>[];
  final deleteCalls = <String>[];

  @override
  Future<TeamEntity> create(TeamEntity team) =>
      createHandler?.call(team) ?? Future.value(team);

  @override
  Future<TeamEntity> createByUser(TeamEntity team, String userId) {
    createByUserCalls.add((team: team, userId: userId));
    return createByUserHandler?.call(team, userId) ?? Future.value(team);
  }

  @override
  Future<bool> delete(String id) {
    deleteCalls.add(id);
    return deleteHandler?.call(id) ?? Future.value(true);
  }

  @override
  Future<List<TeamEntity>> getAll() {
    getAllCalls++;
    return getAllHandler?.call() ?? Future.value(const <TeamEntity>[]);
  }

  @override
  Future<List<TeamEntity>> getAllByUserId(String userId) =>
      getAllByUserIdHandler?.call(userId) ?? Future.value(const <TeamEntity>[]);

  @override
  Future<TeamEntity?> getById(String id) =>
      getByIdHandler?.call(id) ?? Future.value(null);

  @override
  Future<List<TeamEntity>> getLocalOnly() {
    getLocalOnlyCalls++;
    return getLocalOnlyHandler?.call() ?? Future.value(const <TeamEntity>[]);
  }

  @override
  Future<TeamUpdate> update(TeamUpdate team) {
    updateCalls.add(team);
    return updateHandler?.call(team) ?? Future.value(team);
  }
}

class SpyTeamLocalDataSource implements TeamLocalDataSource {
  final savedSnapshots = <List<TeamEntity>>[];

  @override
  Future<void> clearAll() async {}

  @override
  Future<List<TeamEntity>> getAll() async => [];

  @override
  Future<void> saveAll(List<TeamEntity> teams) async {
    savedSnapshots.add(List<TeamEntity>.from(teams));
  }
}

void main() {
  late _FakeTeamRepository repository;
  late TeamUseCase teamUseCase;
  late SpyTeamLocalDataSource teamLocalDataSource;
  late TeamBloc bloc;

  setUp(() {
    repository = _FakeTeamRepository();
    teamUseCase = TeamUseCase(repository);
    teamLocalDataSource = SpyTeamLocalDataSource();
    bloc = TeamBloc(
      teamUseCase: teamUseCase,
      teamLocalDataSource: teamLocalDataSource,
    );
  });

  tearDown(() async {
    await bloc.close();
  });

  group('TeamBloc', () {
    test(
      'LoadTeamsEvent emits local teams first and then refreshed remote teams',
      () async {
        final localTeams = [buildTeam(id: 'local-team', name: 'Local Team')];
        final remoteTeams = [buildTeam(id: 'remote-team', name: 'Remote Team')];
        final remoteCompleter = Completer<List<TeamEntity>>();
        final emittedStates = <TeamState>[];

        repository.getLocalOnlyHandler = () async => localTeams;
        repository.getAllHandler = () => remoteCompleter.future;
        final subscription = bloc.stream.listen(emittedStates.add);

        bloc.add(LoadTeamsEvent());
        await pumpEventQueue();

        expect(emittedStates, hasLength(1));
        expect(
          emittedStates.first,
          isA<TeamsLoaded>().having(
            (state) => state.teams,
            'local teams',
            localTeams,
          ),
        );

        remoteCompleter.complete(remoteTeams);
        await pumpEventQueue(times: 20);

        expect(emittedStates, hasLength(2));
        expect(
          emittedStates.last,
          isA<TeamsLoaded>().having(
            (state) => state.teams,
            'remote teams',
            remoteTeams,
          ),
        );
        expect(repository.getLocalOnlyCalls, 1);
        expect(repository.getAllCalls, 1);

        await subscription.cancel();
      },
    );

    test(
      'LoadTeamsEvent emits loading and then error when no cache is available',
      () async {
        final remoteCompleter = Completer<List<TeamEntity>>();
        final emittedStates = <TeamState>[];

        repository.getLocalOnlyHandler = () async => [];
        repository.getAllHandler = () => remoteCompleter.future;
        final subscription = bloc.stream.listen(emittedStates.add);

        bloc.add(LoadTeamsEvent());
        await pumpEventQueue();

        expect(emittedStates.first, isA<TeamLoading>());

        remoteCompleter.completeError(Exception('network down'));
        await pumpEventQueue(times: 20);

        expect(emittedStates, hasLength(2));
        expect(
          emittedStates.last,
          isA<TeamError>().having(
            (state) => state.message,
            'error message',
            contains('network down'),
          ),
        );

        await subscription.cancel();
      },
    );

    test(
      'CreateTeamEvent creates team by user and persists optimistic cache',
      () async {
        final createdTeam = buildTeam(id: 'team-created', name: 'Created Team');
        final emittedStates = <TeamState>[];
        final refreshCompleter = Completer<List<TeamEntity>>();

        repository.createByUserHandler = (_, __) async => createdTeam;
        repository.getAllHandler = () => refreshCompleter.future;
        final subscription = bloc.stream.listen(emittedStates.add);

        bloc.add(CreateTeamEvent(createdTeam, userId: 'user-42'));
        await pumpEventQueue(times: 30);

        expect(emittedStates.first, isA<TeamCreated>());
        expect(
          emittedStates.whereType<TeamsLoaded>().last.teams.single.id,
          createdTeam.id,
        );
        expect(repository.createByUserCalls, hasLength(1));
        expect(repository.createByUserCalls.single.team, same(createdTeam));
        expect(repository.createByUserCalls.single.userId, 'user-42');
        expect(teamLocalDataSource.savedSnapshots, isNotEmpty);
        expect(
          teamLocalDataSource.savedSnapshots.last.single.id,
          createdTeam.id,
        );

        await subscription.cancel();
        refreshCompleter.complete(const <TeamEntity>[]);
      },
    );

    test('UpdateTeamEvent replaces cached team and persists it', () async {
      final localTeam = buildTeam(id: 'team-1', name: 'Original');
      final updatedTeam = buildTeamUpdate(
        id: 'team-1',
        name: 'Updated name',
        description: 'Updated description',
      );
      final emittedStates = <TeamState>[];
      final refreshCompleter = Completer<List<TeamEntity>>();

      repository.getLocalOnlyHandler = () async => [localTeam];
      repository.getAllHandler = () => refreshCompleter.future;
      repository.updateHandler = (team) async => team;
      final subscription = bloc.stream.listen(emittedStates.add);

      bloc.add(LoadTeamsEvent());
      await pumpEventQueue(times: 20);
      emittedStates.clear();

      bloc.add(UpdateTeamEvent(updatedTeam));
      await pumpEventQueue(times: 30);

      expect(emittedStates.first, isA<TeamUpdated>());
      expect(
        emittedStates.whereType<TeamsLoaded>().last.teams.single.name,
        'Updated name',
      );
      expect(repository.updateCalls, hasLength(1));
      expect(repository.updateCalls.single, same(updatedTeam));
      expect(teamLocalDataSource.savedSnapshots, isNotEmpty);
      expect(
        teamLocalDataSource.savedSnapshots.last.single.name,
        'Updated name',
      );

      await subscription.cancel();
      refreshCompleter.complete(const <TeamEntity>[]);
    });

    test(
      'DeleteTeamEvent removes deleted team from cache when successful',
      () async {
        final localTeam = buildTeam(id: 'team-1', name: 'Original');
        final emittedStates = <TeamState>[];

        repository.getLocalOnlyHandler = () async => [localTeam];
        repository.getAllHandler = () async => [localTeam];
        repository.deleteHandler = (_) async => true;
        final subscription = bloc.stream.listen(emittedStates.add);

        bloc.add(LoadTeamsEvent());
        await pumpEventQueue(times: 20);
        emittedStates.clear();

        bloc.add(const DeleteTeamEvent('team-1'));
        await pumpEventQueue(times: 20);

        expect(emittedStates.first, isA<TeamDeleted>());
        expect(emittedStates.whereType<TeamsLoaded>().last.teams, isEmpty);
        expect(repository.deleteCalls, ['team-1']);
        expect(teamLocalDataSource.savedSnapshots, isNotEmpty);
        expect(teamLocalDataSource.savedSnapshots.last, isEmpty);

        await subscription.cancel();
      },
    );
  });
}
