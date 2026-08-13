import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:note_sondage/feature/auth/domain/entities/auth_user_entity.dart';
import 'package:note_sondage/feature/auth/domain/entities/mfa_factor_hint_entity.dart';
import 'package:note_sondage/feature/auth/domain/entities/phone_sign_in_start_result.dart';
import 'package:note_sondage/feature/auth/domain/entities/totp_enrollment_secret_entity.dart';
import 'package:note_sondage/feature/auth/domain/repositories/auth_repository.dart';
import 'package:note_sondage/feature/auth/domain/use_case/auth_use_case.dart';
import 'package:note_sondage/feature/auth/ui/bloc/auth_bloc.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_assignment_create_request_entity.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_assignment_entity.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_auto_plan_entity.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_profile_entity.dart';
import 'package:note_sondage/feature/shift/domain/repositories/shift_repository.dart';
import 'package:note_sondage/feature/shift/infrastructure/data_source/shift_local_data_source.dart';
import 'package:note_sondage/feature/shift/ui/bloc/shift_bloc.dart';

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository(this._currentUser);

  final AuthUserEntity _currentUser;

  @override
  Stream<AuthUserEntity> get authStateChanges =>
      Stream<AuthUserEntity>.value(_currentUser);

  @override
  AuthUserEntity get currentUser => _currentUser;

  @override
  void clearPendingMfaSignInChallenge() {}

  @override
  Future<AuthUserEntity> confirmPendingMfaSignIn({
    required String sessionId,
    required String smsCode,
  }) => throw UnimplementedError();

  @override
  Future<AuthUserEntity> confirmPendingTotpMfaSignIn({
    required String factorUid,
    required String verificationCode,
  }) => throw UnimplementedError();

  @override
  Future<void> confirmSmsMfaEnrollment({
    required String sessionId,
    required String smsCode,
    String? displayName,
  }) => throw UnimplementedError();

  @override
  Future<AuthUserEntity> confirmPhoneSignIn({
    required String sessionId,
    required String smsCode,
  }) => throw UnimplementedError();

  @override
  Future<void> confirmTotpMfaEnrollment({
    required String verificationCode,
    String? displayName,
  }) => throw UnimplementedError();

  @override
  Future<void> confirmAccountDeletion({required String token}) =>
      throw UnimplementedError();

  @override
  Future<void> confirmAccountReactivation({required String token}) =>
      throw UnimplementedError();

  @override
  Future<AuthUserEntity> createUserWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
    List<int>? profileImageBytes,
    String? profileImageFileName,
  }) => throw UnimplementedError();

  @override
  Future<List<MfaFactorHintEntity>> getEnrolledMfaFactors() =>
      throw UnimplementedError();

  @override
  bool get isAuthenticated => _currentUser.isNotEmpty;

  @override
  Future<void> refreshBackendSession() async {}

  @override
  Future<void> reloadUser() async {}

  @override
  Future<PhoneSignInStartResult> requestPendingMfaSignInCode({
    String? factorUid,
  }) => throw UnimplementedError();

  @override
  Future<void> requestAccountDeletion({required String email}) =>
      throw UnimplementedError();

  @override
  Future<void> requestAccountReactivation({required String email}) =>
      throw UnimplementedError();

  @override
  Future<void> sendEmailVerification() => throw UnimplementedError();

  @override
  Future<void> sendPasswordResetEmail({required String email}) =>
      throw UnimplementedError();

  @override
  Future<AuthUserEntity> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<AuthUserEntity> signInWithGoogle() => throw UnimplementedError();

  @override
  Future<void> signOut() async {}

  @override
  Future<PhoneSignInStartResult> startPhoneSignIn({
    required String phoneNumber,
  }) => throw UnimplementedError();

  @override
  Future<PhoneSignInStartResult> startSmsMfaEnrollment({
    required String phoneNumber,
  }) => throw UnimplementedError();

  @override
  Future<TotpEnrollmentSecretEntity> startTotpMfaEnrollment({
    String? issuer,
    String? accountName,
  }) => throw UnimplementedError();

  @override
  Future<void> updateContactEmail({required String email}) =>
      throw UnimplementedError();

  @override
  Future<void> updateMyProfile({
    String? displayName,
    List<int>? profileImageBytes,
    String? profileImageFileName,
  }) => throw UnimplementedError();
}

class _FakeShiftRepository implements ShiftRepository {
  Future<List<ShiftProfileEntity>> Function()? getProfilesHandler;
  Future<List<ShiftAssignmentEntity>> Function({
    required DateTime from,
    required DateTime to,
    List<String>? visibleTeamIds,
    List<String>? visibleUserIds,
  })?
  getAssignmentsHandler;
  Future<ShiftAssignmentEntity> Function({
    required DateTime shiftDate,
    String? profileId,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    bool? overnight,
    String? note,
    List<int>? alarmOffsets,
    bool isPublic,
    String? teamId,
    String? teamShiftGroupId,
    String? targetUserId,
  })?
  assignHandler;

  int getProfilesCalls = 0;
  int getAssignmentsCalls = 0;
  int assignCalls = 0;

  @override
  Future<ShiftAssignmentEntity> assign({
    required DateTime shiftDate,
    String? profileId,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    bool? overnight,
    String? note,
    List<int>? alarmOffsets,
    bool isPublic = false,
    String? teamId,
    String? teamShiftGroupId,
    String? targetUserId,
  }) {
    assignCalls++;
    return assignHandler?.call(
          shiftDate: shiftDate,
          profileId: profileId,
          startTime: startTime,
          endTime: endTime,
          overnight: overnight,
          note: note,
          alarmOffsets: alarmOffsets,
          isPublic: isPublic,
          teamId: teamId,
          teamShiftGroupId: teamShiftGroupId,
          targetUserId: targetUserId,
        ) ??
        Future<ShiftAssignmentEntity>.error(UnimplementedError());
  }

  @override
  Future<List<ShiftAssignmentEntity>> assignBatch({
    required List<ShiftAssignmentCreateRequestEntity> requests,
  }) => throw UnimplementedError();

  @override
  Future<ShiftAutoPlanResultEntity> autoPlan(
    ShiftAutoPlanRequestEntity request,
  ) => throw UnimplementedError();

  @override
  Future<ShiftAutoPlanPreviewEntity> previewAutoPlan(
    ShiftAutoPlanRequestEntity request,
  ) => throw UnimplementedError();

  @override
  Future<ShiftAutoPlanPreviewEntity> recalculateAutoPlanPreview(
    String snapshotToken,
    List<ShiftAutoPlanDraftAssignmentEntity> draftAssignments,
  ) => throw UnimplementedError();

  @override
  Future<ShiftAutoPlanResultEntity> confirmAutoPlan(String snapshotToken) =>
      throw UnimplementedError();

  @override
  Future<ShiftProfileEntity> createProfile({
    required String name,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required bool overnight,
    required List<int> alarmOffsets,
    String? color,
    bool isPublic = false,
  }) => throw UnimplementedError();

  @override
  Future<void> deleteAssignment(String assignmentId) =>
      throw UnimplementedError();

  @override
  Future<void> deleteProfile(String profileId) => throw UnimplementedError();

  @override
  Future<List<ShiftAssignmentEntity>> getAssignments({
    required DateTime from,
    required DateTime to,
    List<String>? visibleTeamIds,
    List<String>? visibleUserIds,
  }) {
    getAssignmentsCalls++;
    return getAssignmentsHandler?.call(
          from: from,
          to: to,
          visibleTeamIds: visibleTeamIds,
          visibleUserIds: visibleUserIds,
        ) ??
        Future.value(const <ShiftAssignmentEntity>[]);
  }

  @override
  Future<List<ShiftProfileEntity>> getProfiles() {
    getProfilesCalls++;
    return getProfilesHandler?.call() ??
        Future.value(const <ShiftProfileEntity>[]);
  }

  @override
  Future<void> requestAssignmentChange(
    String assignmentId, {
    String? profileId,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    bool? overnight,
    String? note,
    List<int>? alarmOffsets,
  }) => throw UnimplementedError();

  @override
  Future<void> requestAssignmentSwap(
    String assignmentId, {
    required String candidateUserId,
    String? note,
  }) => throw UnimplementedError();

  @override
  Future<ShiftAssignmentEntity> updateAssignment(
    String assignmentId, {
    String? profileId,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    bool? overnight,
    String? note,
    List<int>? alarmOffsets,
    bool isPublic = false,
    String? teamId,
    String? teamShiftGroupId,
    String? targetUserId,
  }) => throw UnimplementedError();

  @override
  Future<ShiftProfileEntity> updateProfile(
    String profileId, {
    required String name,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required bool overnight,
    required List<int> alarmOffsets,
    String? color,
    bool isPublic = false,
  }) => throw UnimplementedError();
}

class SpyShiftLocalDataSource extends ShiftLocalDataSource {
  List<ShiftProfileEntity> storedProfiles = <ShiftProfileEntity>[];
  List<ShiftAssignmentEntity> storedAssignments = <ShiftAssignmentEntity>[];
  final savedProfileSnapshots = <List<ShiftProfileEntity>>[];
  final savedAssignmentSnapshots = <List<ShiftAssignmentEntity>>[];

  @override
  Future<List<ShiftProfileEntity>> getProfiles() async => storedProfiles;

  @override
  Future<void> saveProfiles(List<ShiftProfileEntity> profiles) async {
    storedProfiles = List<ShiftProfileEntity>.from(profiles);
    savedProfileSnapshots.add(List<ShiftProfileEntity>.from(profiles));
  }

  @override
  Future<List<ShiftAssignmentEntity>> getAssignments({
    DateTime? from,
    DateTime? to,
  }) async => storedAssignments;

  @override
  Future<void> saveAssignments(List<ShiftAssignmentEntity> assignments) async {
    storedAssignments = List<ShiftAssignmentEntity>.from(assignments);
    savedAssignmentSnapshots.add(List<ShiftAssignmentEntity>.from(assignments));
  }
}

ShiftProfileEntity _buildProfile({
  required String id,
  required String name,
  String? color = '#00AACC',
}) {
  return ShiftProfileEntity(
    id: id,
    userId: 'user-1',
    name: name,
    color: color,
    startTime: const TimeOfDay(hour: 8, minute: 0),
    endTime: const TimeOfDay(hour: 16, minute: 0),
    overnight: false,
    isSystem: false,
    alarmOffsets: const <int>[30],
  );
}

ShiftAssignmentEntity _buildAssignment({
  required String id,
  required String userId,
  required DateTime shiftDate,
  String? teamId,
  String? profileId,
  String? profileName,
}) {
  return ShiftAssignmentEntity(
    id: id,
    userId: userId,
    userName: 'Mario Rossi',
    shiftDate: shiftDate,
    teamId: teamId,
    teamShiftGroupId: teamId == null ? null : 'group-1',
    profileId: profileId,
    profileName: profileName,
    profileColor: '#00AACC',
    startTime: const TimeOfDay(hour: 8, minute: 0),
    endTime: const TimeOfDay(hour: 16, minute: 0),
    overnight: false,
    note: 'turno',
    alarmOffsets: const <int>[30],
    isPublic: teamId != null,
  );
}

void main() {
  final getIt = GetIt.instance;

  late _FakeShiftRepository repository;
  late SpyShiftLocalDataSource localDataSource;
  late AuthBloc authBloc;
  late ShiftBloc bloc;

  setUp(() async {
    await getIt.reset();
    repository = _FakeShiftRepository();
    localDataSource = SpyShiftLocalDataSource();
    authBloc = AuthBloc(
      authUseCase: AuthUseCase(
        _FakeAuthRepository(
          const AuthUserEntity(
            uid: 'user-42',
            email: 'mario@example.com',
            displayName: 'Mario Rossi',
          ),
        ),
      ),
    );
    getIt.registerSingleton<AuthBloc>(authBloc);
    await pumpEventQueue(times: 5);
    bloc = ShiftBloc(repository, localDataSource);
  });

  tearDown(() async {
    await bloc.close();
    await authBloc.close();
    await getIt.reset();
  });

  group('ShiftBloc', () {
    test(
      'LoadShiftProfilesEvent emits local profiles first and then refreshed remote profiles',
      () async {
        final localProfiles = <ShiftProfileEntity>[
          _buildProfile(id: 'local-profile', name: 'Locale'),
        ];
        final remoteProfiles = <ShiftProfileEntity>[
          _buildProfile(id: 'remote-profile', name: 'Remoto'),
        ];
        final completer = Completer<List<ShiftProfileEntity>>();
        final emittedStates = <ShiftState>[];

        localDataSource.storedProfiles = localProfiles;
        repository.getProfilesHandler = () => completer.future;
        final subscription = bloc.stream.listen(emittedStates.add);

        bloc.add(LoadShiftProfilesEvent());
        await pumpEventQueue();

        expect(
          emittedStates.first,
          isA<ShiftProfilesLoaded>().having(
            (state) => state.profiles.map((profile) => profile.id).toList(),
            'local profile ids',
            <String>['local-profile'],
          ),
        );

        completer.complete(remoteProfiles);
        await pumpEventQueue(times: 20);

        expect(
          emittedStates.last,
          isA<ShiftProfilesLoaded>().having(
            (state) => state.profiles.map((profile) => profile.id).toList(),
            'remote profile ids',
            <String>['remote-profile'],
          ),
        );
        expect(repository.getProfilesCalls, 1);
        expect(
          localDataSource.savedProfileSnapshots.last
              .map((profile) => profile.id)
              .toList(),
          <String>['remote-profile'],
        );

        await subscription.cancel();
      },
    );

    test(
      'AssignShiftEvent emits optimistic assignment for current user and then committed assignment',
      () async {
        final shiftDate = DateTime(2026, 7, 20);
        final emittedStates = <ShiftState>[];
        final remoteAssignment = _buildAssignment(
          id: 'server-assignment',
          userId: 'user-42',
          shiftDate: shiftDate,
          teamId: 'team-1',
        );

        repository.assignHandler =
            ({
              required shiftDate,
              profileId,
              startTime,
              endTime,
              overnight,
              note,
              alarmOffsets,
              isPublic = false,
              teamId,
              teamShiftGroupId,
              targetUserId,
            }) async => remoteAssignment;

        final subscription = bloc.stream.listen(emittedStates.add);

        bloc.add(
          AssignShiftEvent(
            shiftDate: shiftDate,
            startTime: const TimeOfDay(hour: 10, minute: 0),
            endTime: const TimeOfDay(hour: 18, minute: 0),
            note: 'Copertura team',
            alarmOffsets: const <int>[10],
            isPublic: true,
            teamId: 'team-1',
          ),
        );
        await pumpEventQueue(times: 30);

        expect(
          emittedStates.first,
          isA<ShiftAssigned>()
              .having((state) => state.assignment.userId, 'user id', 'user-42')
              .having(
                (state) => state.assignment.userName,
                'user name',
                'Mario Rossi',
              )
              .having(
                (state) => state.assignment.startTime,
                'start time',
                const TimeOfDay(hour: 10, minute: 0),
              )
              .having((state) => state.assignment.teamId, 'team', 'team-1'),
        );
        expect(
          emittedStates.last,
          isA<ShiftAssignmentsLoaded>().having(
            (state) => state.assignments.single.id,
            'committed id',
            'server-assignment',
          ),
        );
        expect(repository.assignCalls, 1);
        expect(
          localDataSource.savedAssignmentSnapshots.last.single.id,
          'server-assignment',
        );

        await subscription.cancel();
      },
    );

    test(
      'AssignShiftEvent rolls back optimistic cache when repository fails',
      () async {
        final existingAssignment = _buildAssignment(
          id: 'existing',
          userId: 'user-42',
          shiftDate: DateTime(2026, 7, 18),
        );
        final emittedStates = <ShiftState>[];

        localDataSource.storedAssignments = <ShiftAssignmentEntity>[
          existingAssignment,
        ];
        repository.getAssignmentsHandler =
            ({
              required from,
              required to,
              visibleTeamIds,
              visibleUserIds,
            }) async => <ShiftAssignmentEntity>[existingAssignment];
        repository.assignHandler =
            ({
              required shiftDate,
              profileId,
              startTime,
              endTime,
              overnight,
              note,
              alarmOffsets,
              isPublic = false,
              teamId,
              teamShiftGroupId,
              targetUserId,
            }) =>
                Future<ShiftAssignmentEntity>.error(Exception('backend down'));

        bloc.add(
          LoadShiftAssignmentsEvent(
            from: DateTime(2026, 7, 1),
            to: DateTime(2026, 7, 31),
          ),
        );
        await pumpEventQueue(times: 20);

        final subscription = bloc.stream.listen(emittedStates.add);

        bloc.add(
          AssignShiftEvent(
            shiftDate: DateTime(2026, 7, 19),
            startTime: const TimeOfDay(hour: 9, minute: 0),
            endTime: const TimeOfDay(hour: 17, minute: 0),
          ),
        );
        await pumpEventQueue(times: 30);

        expect(emittedStates.first, isA<ShiftAssigned>());
        expect(
          emittedStates[1],
          isA<ShiftError>().having(
            (state) => state.message,
            'error message',
            contains('backend down'),
          ),
        );
        expect(
          emittedStates.last,
          isA<ShiftAssignmentsLoaded>().having(
            (state) =>
                state.assignments.map((assignment) => assignment.id).toList(),
            'rolled back assignment ids',
            <String>['existing'],
          ),
        );
        expect(
          localDataSource.savedAssignmentSnapshots.last
              .map((assignment) => assignment.id)
              .toList(),
          <String>['existing'],
        );

        await subscription.cancel();
      },
    );
  });
}
