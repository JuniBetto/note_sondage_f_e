import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:note_sondage/feature/team/domain/repositories/team_repository.dart';
import 'package:note_sondage/feature/team/domain/use_case/team/team_use_case.dart';

import '../../../../support/team_fixtures.dart';

class MockTeamRepository extends Mock implements TeamRepository {}

void main() {
  late MockTeamRepository repository;
  late TeamUseCase useCase;

  setUp(() {
    repository = MockTeamRepository();
    useCase = TeamUseCase(repository);
  });

  group('TeamUseCase', () {
    test('getAllTeams returns repository teams', () async {
      final teams = [buildTeam(), buildTeam(id: 'team-2', name: 'Design')];
      when(repository.getAll()).thenAnswer((_) async => teams);

      final result = await useCase.getAllTeams();

      expect(result, same(teams));
      verify(repository.getAll()).called(1);
    });

    test('getAllTeamsByUserId wraps repository errors', () async {
      when(
        repository.getAllByUserId('user-42'),
      ).thenThrow(Exception('backend down'));

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
      when(
        repository.createByUser(team, 'user-42'),
      ).thenAnswer((_) async => team);

      final result = await useCase.createTeamByUser(team, 'user-42');

      expect(result, same(team));
      verify(repository.createByUser(team, 'user-42')).called(1);
    });

    test('getLocalTeams returns repository local cache', () async {
      final localTeams = [buildTeam(id: 'local-team')];
      when(repository.getLocalOnly()).thenAnswer((_) async => localTeams);

      final result = await useCase.getLocalTeams();

      expect(result, same(localTeams));
      verify(repository.getLocalOnly()).called(1);
    });
  });
}
