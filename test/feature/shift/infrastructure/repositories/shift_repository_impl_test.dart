import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_assignment_entity.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_auto_plan_entity.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_profile_entity.dart';
import 'package:note_sondage/feature/shift/infrastructure/data_source/shift_local_data_source.dart';
import 'package:note_sondage/feature/shift/infrastructure/data_source/shift_remote_data_source.dart';
import 'package:note_sondage/feature/shift/infrastructure/repositories/shift_repository_impl.dart';

void main() {
  group('ShiftRepositoryImpl auto planner', () {
    test(
      'previewAutoPlan delegates to remote and does not mutate local cache',
      () async {
        final local = _FakeShiftLocalDataSource();
        final remote = _FakeShiftRemoteDataSource()..previewResult = _preview();
        final repository = ShiftRepositoryImpl(local, remote);

        final result = await repository.previewAutoPlan(_request());

        expect(remote.previewRequests, hasLength(1));
        expect(result.snapshotToken, 'snapshot-1');
        expect(local.savedAssignmentsSnapshots, isEmpty);
        expect(local.savedProfilesSnapshots, isEmpty);
      },
    );

    test(
      'confirmAutoPlan delegates to remote and returns final planner result',
      () async {
        final local = _FakeShiftLocalDataSource();
        final remote = _FakeShiftRemoteDataSource()..confirmResult = _result();
        final repository = ShiftRepositoryImpl(local, remote);

        final result = await repository.confirmAutoPlan('snapshot-1');

        expect(remote.confirmTokens, ['snapshot-1']);
        expect(result.createdAssignmentsCount, 2);
        expect(local.savedAssignmentsSnapshots, isEmpty);
        expect(local.savedProfilesSnapshots, isEmpty);
      },
    );
  });
}

class _FakeShiftLocalDataSource extends ShiftLocalDataSource {
  final savedProfilesSnapshots = <List<ShiftProfileEntity>>[];
  final savedAssignmentsSnapshots = <List<ShiftAssignmentEntity>>[];

  @override
  Future<void> saveProfiles(List<ShiftProfileEntity> profiles) async {
    savedProfilesSnapshots.add(List<ShiftProfileEntity>.from(profiles));
  }

  @override
  Future<void> saveAssignments(List<ShiftAssignmentEntity> assignments) async {
    savedAssignmentsSnapshots.add(
      List<ShiftAssignmentEntity>.from(assignments),
    );
  }

  @override
  Future<List<ShiftProfileEntity>> getProfiles() async => const [];

  @override
  Future<List<ShiftAssignmentEntity>> getAssignments({
    DateTime? from,
    DateTime? to,
  }) async => const [];
}

class _FakeShiftRemoteDataSource extends ShiftRemoteDataSource {
  _FakeShiftRemoteDataSource() : super(dio: Dio());

  final previewRequests = <ShiftAutoPlanRequestEntity>[];
  final confirmTokens = <String>[];
  ShiftAutoPlanPreviewEntity? previewResult;
  ShiftAutoPlanResultEntity? confirmResult;

  @override
  Future<ShiftAutoPlanPreviewEntity> previewAutoPlan(
    ShiftAutoPlanRequestEntity request,
  ) async {
    previewRequests.add(request);
    return previewResult!;
  }

  @override
  Future<ShiftAutoPlanResultEntity> confirmAutoPlan(
    String snapshotToken,
  ) async {
    confirmTokens.add(snapshotToken);
    return confirmResult!;
  }
}

ShiftAutoPlanRequestEntity _request() {
  return ShiftAutoPlanRequestEntity(
    teamId: 'team-1',
    from: DateTime(2026, 8, 1),
    to: DateTime(2026, 8, 3),
    plannerMode: ShiftAutoPlannerMode.rotation,
    replaceExistingAssignments: false,
    templates: const [
      ShiftAutoPlanTemplateEntity(
        profileId: 'profile-1',
        requiredMemberCount: 2,
      ),
    ],
  );
}

ShiftAutoPlanPreviewEntity _preview() {
  return ShiftAutoPlanPreviewEntity(
    snapshotToken: 'snapshot-1',
    fullyFeasible: true,
    createdAssignmentsCountPreview: 2,
    preservedAssignmentsCount: 1,
    deletedAssignmentsCountPreview: 0,
    uncoveredSlotsCount: 0,
    warnings: const [],
    days: [
      ShiftAutoPlanPreviewDayEntity(
        date: DateTime(2026, 8, 1),
        items: [
          ShiftAutoPlanPreviewAssignmentEntity(
            action: ShiftAutoPlanPreviewAction.create,
            assignment: ShiftAssignmentEntity(
              id: 'assignment-1',
              userId: 'user-1',
              userName: 'Mario Rossi',
              shiftDate: DateTime(2026, 8, 1),
              teamId: 'team-1',
              teamShiftGroupId: 'group-1',
              profileId: 'profile-1',
              profileName: 'Mattina',
              profileColor: '#00AAFF',
              startTime: const TimeOfDay(hour: 8, minute: 0),
              endTime: const TimeOfDay(hour: 12, minute: 0),
              overnight: false,
              note: null,
              alarmOffsets: const <int>[],
              isPublic: true,
              memberEditUnlocked: false,
              memberChangeRequestPending: false,
            ),
          ),
        ],
      ),
    ],
  );
}

ShiftAutoPlanResultEntity _result() {
  return const ShiftAutoPlanResultEntity(
    createdAssignmentsCount: 2,
    preservedAssignmentsCount: 1,
    uncoveredSlotsCount: 0,
    warnings: [],
  );
}
