import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';
import 'package:note_sondage/feature/team/domain/use_case/team/team_use_case.dart';
import 'package:note_sondage/feature/team/infrastructure/data_source/data_source_local/team_local_data_source.dart';
import 'package:note_sondage/feature/team/ui/bloc/team/team_bloc.dart';

import '../../../../../support/team_fixtures.dart';

class MockTeamUseCase extends Mock implements TeamUseCase {}

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
  late MockTeamUseCase teamUseCase;
  late SpyTeamLocalDataSource teamLocalDataSource;
  late TeamBloc bloc;

  setUp(() {
    teamUseCase = MockTeamUseCase();
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
    test('LoadTeamsEvent emits local teams first and then refreshed remote teams',
        () async {
      final localTeams = [buildTeam(id: 'local-team', name: 'Local Team')];
      final remoteTeams = [buildTeam(id: 'remote-team', name: 'Remote Team')];
      final remoteCompleter = Completer<List<TeamEntity>>();
      final emittedStates = <TeamState>[];

      when(teamUseCase.getLocalTeams()).thenAnswer((_) async => localTeams);
      when(teamUseCase.getAllTeams()).thenAnswer((_) => remoteCompleter.future);
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
      verify(teamUseCase.getLocalTeams()).called(1);
      verify(teamUseCase.getAllTeams()).called(1);

      await subscription.cancel();
    });

    test('LoadTeamsEvent emits loading and then error when no cache is available',
        () async {
      final remoteCompleter = Completer<List<TeamEntity>>();
      final emittedStates = <TeamState>[];

      when(teamUseCase.getLocalTeams()).thenAnswer((_) async => []);
      when(teamUseCase.getAllTeams()).thenAnswer((_) => remoteCompleter.future);
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
    });

    test('CreateTeamEvent creates team by user and persists optimistic cache',
        () async {
      final createdTeam = buildTeam(id: 'team-created', name: 'Created Team');
      final emittedStates = <TeamState>[];

      when(
        teamUseCase.createTeamByUser(createdTeam, 'user-42'),
      ).thenAnswer((_) async => createdTeam);
      final subscription = bloc.stream.listen(emittedStates.add);

      bloc.add(CreateTeamEvent(createdTeam, userId: 'user-42'));
      await pumpEventQueue(times: 20);

      expect(emittedStates, hasLength(2));
      expect(
        emittedStates.first,
        isA<TeamCreated>().having((state) => state.team, 'created team', createdTeam),
      );
      expect(
        emittedStates.last,
        isA<TeamsLoaded>().having(
          (state) => state.teams,
          'cached teams',
          [createdTeam],
        ),
      );
      verify(teamUseCase.createTeamByUser(createdTeam, 'user-42')).called(1);
      expect(teamLocalDataSource.savedSnapshots, hasLength(1));
      final createdSavedTeams = teamLocalDataSource.savedSnapshots.single;
      expect(createdSavedTeams, hasLength(1));
      expect(createdSavedTeams.first.id, createdTeam.id);
      expect(createdSavedTeams.first.name, createdTeam.name);
      await subscription.cancel();
    });

    test('UpdateTeamEvent replaces cached team and persists it', () async {
      final localTeam = buildTeam(id: 'team-1', name: 'Original');
      final updatedTeam = buildTeamUpdate(
        id: 'team-1',
        name: 'Updated name',
        description: 'Updated description',
      );
      final emittedStates = <TeamState>[];

      when(teamUseCase.getLocalTeams()).thenAnswer((_) async => [localTeam]);
      when(teamUseCase.getAllTeams()).thenAnswer((_) async => [localTeam]);
      when(teamUseCase.updateTeam(updatedTeam)).thenAnswer((_) async => updatedTeam);
      final subscription = bloc.stream.listen(emittedStates.add);

      bloc.add(LoadTeamsEvent());
      await pumpEventQueue(times: 20);
      emittedStates.clear();

      bloc.add(UpdateTeamEvent(updatedTeam));
      await pumpEventQueue(times: 20);

      expect(emittedStates, hasLength(2));
      expect(
        emittedStates.first,
        isA<TeamUpdated>().having((state) => state.team, 'updated team', updatedTeam),
      );
      expect(
        emittedStates.last,
        isA<TeamsLoaded>().having(
          (state) => state.teams.single.name,
          'updated cached name',
          'Updated name',
        ),
      );
      verify(teamUseCase.updateTeam(updatedTeam)).called(1);
      expect(teamLocalDataSource.savedSnapshots, hasLength(1));
      final updatedSavedTeams = teamLocalDataSource.savedSnapshots.single;
      expect(updatedSavedTeams, hasLength(1));
      expect(updatedSavedTeams.first.id, updatedTeam.id);
      expect(updatedSavedTeams.first.name, updatedTeam.name);

      await subscription.cancel();
    });

    test('DeleteTeamEvent removes deleted team from cache when successful',
        () async {
      final localTeam = buildTeam(id: 'team-1', name: 'Original');
      final emittedStates = <TeamState>[];

      when(teamUseCase.getLocalTeams()).thenAnswer((_) async => [localTeam]);
      when(teamUseCase.getAllTeams()).thenAnswer((_) async => [localTeam]);
      when(teamUseCase.deleteTeam('team-1')).thenAnswer((_) async => true);
      final subscription = bloc.stream.listen(emittedStates.add);

      bloc.add(LoadTeamsEvent());
      await pumpEventQueue(times: 20);
      emittedStates.clear();

      bloc.add(const DeleteTeamEvent('team-1'));
      await pumpEventQueue(times: 20);

      expect(emittedStates, hasLength(2));
      expect(emittedStates.first, isA<TeamDeleted>());
      expect(
        emittedStates.last,
        isA<TeamsLoaded>().having(
          (state) => state.teams,
          'cached teams after deletion',
          isEmpty,
        ),
      );
      verify(teamUseCase.deleteTeam('team-1')).called(1);
      expect(teamLocalDataSource.savedSnapshots, hasLength(1));
      final deletedSavedTeams = teamLocalDataSource.savedSnapshots.single;
      expect(deletedSavedTeams, isEmpty);

      await subscription.cancel();
    });
  });
}
