import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:note_sondage/feature/chat/ui/bloc/chat/chat_bloc.dart';
import 'package:note_sondage/feature/team/domain/entities/planning_worker_type_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/role_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/team_invitation_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/team_member_clocking_alarm_override_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/team_member_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/team_member_planning_constraints_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/user_status.dart';
import 'package:note_sondage/feature/team/domain/repositories/role_repository.dart';
import 'package:note_sondage/feature/team/domain/repositories/team_member_repository.dart';
import 'package:note_sondage/feature/team/domain/repositories/team_repository.dart';
import 'package:note_sondage/feature/team/domain/use_case/role/role_use_case.dart';
import 'package:note_sondage/feature/team/domain/use_case/team/team_use_case.dart';
import 'package:note_sondage/feature/team/domain/use_case/team_member/team_member_use_case.dart';

import '../../../../../support/team_fixtures.dart';

class _FakeTeamRepository implements TeamRepository {
  Future<List<TeamEntity>> Function()? getAllHandler;
  int getAllCalls = 0;

  @override
  Future<List<TeamEntity>> getAll() {
    getAllCalls++;
    return getAllHandler?.call() ?? Future.value(const <TeamEntity>[]);
  }

  @override
  Future<TeamEntity> create(TeamEntity team) => throw UnimplementedError();

  @override
  Future<TeamEntity> createByUser(TeamEntity team, String userId) =>
      throw UnimplementedError();

  @override
  Future<bool> delete(String id) => throw UnimplementedError();

  @override
  Future<List<TeamEntity>> getAllByUserId(String userId) =>
      throw UnimplementedError();

  @override
  Future<TeamEntity?> getById(String id) => throw UnimplementedError();

  @override
  Future<List<TeamEntity>> getLocalOnly() => throw UnimplementedError();

  @override
  Future<TeamUpdate> update(TeamUpdate team) => throw UnimplementedError();

  @override
  Future<List<PlanningWorkerTypeEntity>> updatePlanningWorkerTypes(
    String teamId,
    List<PlanningWorkerTypeEntity> workerTypes,
  ) => throw UnimplementedError();
}

class _FakeTeamMemberRepository implements TeamMemberRepository {
  final membersByTeamId = <String, List<TeamMemberEntity>>{};
  final errorForTeamId = <String, Object>{};
  final getAllByTeamIdCalls = <String>[];

  @override
  Future<List<TeamMemberEntity>> getAllByTeamId(String teamId) async {
    getAllByTeamIdCalls.add(teamId);
    final error = errorForTeamId[teamId];
    if (error != null) {
      throw error;
    }
    return membersByTeamId[teamId] ?? const <TeamMemberEntity>[];
  }

  @override
  Future<List<TeamMemberEntity>> getAll() => throw UnimplementedError();

  @override
  Future<TeamMemberEntity?> getById(String id) => throw UnimplementedError();

  @override
  Future<TeamMemberEntity> create(TeamMemberEntity member) =>
      throw UnimplementedError();

  @override
  Future<TeamMemberEntity> update(TeamMemberEntity member) =>
      throw UnimplementedError();

  @override
  Future<bool> delete(String id) => throw UnimplementedError();

  @override
  Future<bool> inviteMember(String teamId, String email, String roleId) =>
      throw UnimplementedError();

  @override
  Future<List<TeamInvitationEntity>> getPendingInvitations(String teamId) =>
      throw UnimplementedError();

  @override
  Future<void> cancelInvitation(String teamId, String invitationId) =>
      throw UnimplementedError();

  @override
  Future<TeamMemberEntity> updatePlanningConstraints({
    required String teamId,
    required String memberId,
    required TeamMemberPlanningConstraintsEntity constraints,
  }) => throw UnimplementedError();

  @override
  Future<TeamMemberEntity> updateClockingAlarmOverride({
    required String teamId,
    required String memberId,
    required TeamMemberClockingAlarmOverrideEntity override,
  }) => throw UnimplementedError();

  @override
  Future<TeamMemberEntity> uploadProfileImage({
    required String memberId,
    File? imageFile,
    Uint8List? imageBytes,
    String? fileName,
  }) => throw UnimplementedError();
}

class _FakeRoleRepository implements RoleRepository {
  final rolesByTeamId = <String, List<RoleEntity>>{};
  final errorForTeamId = <String, Object>{};
  final getAllRolesByTeamIdCalls = <String>[];

  @override
  Future<List<RoleEntity>> getAllRolesByTeamId(String teamId) async {
    getAllRolesByTeamIdCalls.add(teamId);
    final error = errorForTeamId[teamId];
    if (error != null) {
      throw error;
    }
    return rolesByTeamId[teamId] ?? const <RoleEntity>[];
  }

  @override
  Future<List<RoleEntity>> getAll() => throw UnimplementedError();

  @override
  Future<RoleEntity?> getRoleById(String id) => throw UnimplementedError();

  @override
  Future<RoleEntity> createRole(RoleEntity role) => throw UnimplementedError();

  @override
  Future<RoleEntity> updateRole(RoleEntity role) => throw UnimplementedError();

  @override
  Future<bool> deleteRole(String id) => throw UnimplementedError();
}

void main() {
  late _FakeTeamRepository teamRepository;
  late _FakeTeamMemberRepository teamMemberRepository;
  late _FakeRoleRepository roleRepository;
  late ChatBloc bloc;

  setUp(() {
    teamRepository = _FakeTeamRepository();
    teamMemberRepository = _FakeTeamMemberRepository();
    roleRepository = _FakeRoleRepository();
    bloc = ChatBloc(
      teamUseCase: TeamUseCase(teamRepository),
      teamMemberUseCase: TeamMemberUseCase(teamMemberRepository),
      roleUseCase: RoleUseCase(roleRepository),
    );
  });

  tearDown(() async => bloc.close());

  group('ChatBloc teams', () {
    test(
      'ChatTeamsRequested selects the first team when none is preferred',
      () async {
        final teams = [buildTeam(), buildTeam(id: 'team-2', name: 'Design')];
        teamRepository.getAllHandler = () async => teams;

        final emittedStates = <ChatState>[];
        final subscription = bloc.stream.listen(emittedStates.add);

        bloc.add(const ChatTeamsRequested());
        await pumpEventQueue();

        expect(emittedStates.first.loadingTeams, isTrue);
        final loaded = emittedStates.last;
        expect(loaded.loadingTeams, isFalse);
        expect(loaded.teams, teams);
        expect(loaded.selectedTeamId, 'team-1');

        await subscription.cancel();
      },
    );

    test(
      'ChatTeamsRequested honors an explicit preferredTeamId over the '
      'current selection',
      () async {
        final teams = [buildTeam(), buildTeam(id: 'team-2', name: 'Design')];
        teamRepository.getAllHandler = () async => teams;

        final emittedStates = <ChatState>[];
        final subscription = bloc.stream.listen(emittedStates.add);

        bloc.add(const ChatTeamsRequested(preferredTeamId: 'team-2'));
        await pumpEventQueue();

        expect(emittedStates.last.selectedTeamId, 'team-2');

        await subscription.cancel();
      },
    );

    test(
      'ChatTeamsRequested keeps the current selection when it is still '
      'valid and nothing is explicitly preferred',
      () async {
        teamRepository.getAllHandler = () async => [
          buildTeam(),
          buildTeam(id: 'team-2', name: 'Design'),
        ];
        bloc.add(const ChatTeamsRequested(preferredTeamId: 'team-2'));
        await pumpEventQueue();
        expect(bloc.state.selectedTeamId, 'team-2');

        bloc.add(const ChatTeamsRequested());
        await pumpEventQueue();

        expect(bloc.state.selectedTeamId, 'team-2');
      },
    );

    test('ChatTeamsRequested clears the selection when there are no teams', () async {
      teamRepository.getAllHandler = () async => const <TeamEntity>[];

      bloc.add(const ChatTeamsRequested());
      await pumpEventQueue();

      expect(bloc.state.teams, isEmpty);
      expect(bloc.state.selectedTeamId, isNull);
    });

    test(
      'ChatTeamsRequested surfaces a transient error and stops loading on '
      'failure',
      () async {
        teamRepository.getAllHandler = () =>
            Future<List<TeamEntity>>.error(Exception('backend down'));

        bloc.add(const ChatTeamsRequested());
        await pumpEventQueue();

        expect(bloc.state.loadingTeams, isFalse);
        expect(bloc.state.transient, isA<ChatErrorOccurred>());
      },
    );
  });

  group('ChatBloc team access context', () {
    test(
      'ChatTeamAccessContextRequested loads and caches members and roles',
      () async {
        teamMemberRepository.membersByTeamId['team-1'] = [
          TeamMemberEntity(
            userId: 'user-1',
            userEmail: 'mario@example.com',
            teamId: 'team-1',
            status: UserStatus.active,
            roleId: 'role-1',
          ),
        ];
        roleRepository.rolesByTeamId['team-1'] = [
          RoleEntity('role-1', teamId: 'team-1', name: 'Admin', permissions: const []),
        ];

        bloc.add(const ChatTeamAccessContextRequested('team-1'));
        await pumpEventQueue();

        expect(bloc.state.teamMembersByTeamId['team-1'], hasLength(1));
        expect(bloc.state.rolesByTeamId['team-1'], hasLength(1));
      },
    );

    test(
      'ChatTeamAccessContextRequested does not refetch an already-cached team',
      () async {
        teamMemberRepository.membersByTeamId['team-1'] = const [];
        roleRepository.rolesByTeamId['team-1'] = const [];

        bloc.add(const ChatTeamAccessContextRequested('team-1'));
        await pumpEventQueue();
        bloc.add(const ChatTeamAccessContextRequested('team-1'));
        await pumpEventQueue();

        expect(teamMemberRepository.getAllByTeamIdCalls, ['team-1']);
        expect(roleRepository.getAllRolesByTeamIdCalls, ['team-1']);
      },
    );

    test(
      'ChatTeamAccessContextRequested fired twice back-to-back for the same '
      'team only fetches once (sequential processing + cache check dedupe)',
      () async {
        bloc
          ..add(const ChatTeamAccessContextRequested('team-1'))
          ..add(const ChatTeamAccessContextRequested('team-1'));
        await pumpEventQueue();

        expect(teamMemberRepository.getAllByTeamIdCalls, ['team-1']);
        expect(roleRepository.getAllRolesByTeamIdCalls, ['team-1']);
      },
    );

    test(
      'ChatTeamAccessContextRequested silently swallows errors without '
      'crashing the bloc',
      () async {
        teamMemberRepository.errorForTeamId['team-1'] = Exception('boom');
        roleRepository.errorForTeamId['team-1'] = Exception('boom');

        bloc.add(const ChatTeamAccessContextRequested('team-1'));
        await pumpEventQueue();

        expect(bloc.state.teamMembersByTeamId.containsKey('team-1'), isFalse);
        expect(bloc.state.rolesByTeamId.containsKey('team-1'), isFalse);
        expect(bloc.state.transient, isNull);
      },
    );

    test('ChatTeamAccessContextRequested ignores a blank team id', () async {
      bloc.add(const ChatTeamAccessContextRequested('  '));
      await pumpEventQueue();

      expect(teamMemberRepository.getAllByTeamIdCalls, isEmpty);
      expect(roleRepository.getAllRolesByTeamIdCalls, isEmpty);
    });
  });
}
