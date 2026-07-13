import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_assignment_entity.dart';
import 'package:note_sondage/feature/shift/ui/shift_assignment_access_policy.dart';

void main() {
  ShiftAssignmentEntity buildAssignment({
    required String id,
    required String userId,
    String? teamId,
    required bool isPublic,
    bool memberEditUnlocked = false,
  }) {
    return ShiftAssignmentEntity(
      id: id,
      userId: userId,
      shiftDate: DateTime(2026, 7, 13),
      teamId: teamId,
      startTime: const TimeOfDay(hour: 9, minute: 0),
      endTime: const TimeOfDay(hour: 18, minute: 0),
      overnight: false,
      alarmOffsets: const <int>[],
      isPublic: isPublic,
      memberEditUnlocked: memberEditUnlocked,
    );
  }

  group('ShiftAssignmentAccessPolicy', () {
    test('lets the owner manage a public personal shift', () {
      final assignment = buildAssignment(
        id: 'shift-1',
        userId: 'user-1',
        isPublic: true,
      );

      final canManage = ShiftAssignmentAccessPolicy.canManageAssignment(
        assignment,
        currentUserId: 'user-1',
        manageableTeamIds: const <String>[],
      );

      expect(canManage, isTrue);
      expect(
        ShiftAssignmentAccessPolicy.canRequestAssignmentChange(
          assignment,
          currentUserId: 'user-1',
          canManageAssignment: canManage,
        ),
        isFalse,
      );
    });

    test('opens request-change only for team public shifts', () {
      final assignment = buildAssignment(
        id: 'shift-2',
        userId: 'user-1',
        teamId: 'team-1',
        isPublic: true,
      );

      final canManage = ShiftAssignmentAccessPolicy.canManageAssignment(
        assignment,
        currentUserId: 'user-1',
        manageableTeamIds: const <String>[],
      );

      expect(canManage, isFalse);
      expect(
        ShiftAssignmentAccessPolicy.canRequestAssignmentChange(
          assignment,
          currentUserId: 'user-1',
          canManageAssignment: canManage,
        ),
        isTrue,
      );
    });

    test('allows approved self-edit only for team public shifts', () {
      final teamAssignment = buildAssignment(
        id: 'shift-3',
        userId: 'user-1',
        teamId: 'team-1',
        isPublic: true,
        memberEditUnlocked: true,
      );
      final personalAssignment = buildAssignment(
        id: 'shift-4',
        userId: 'user-1',
        isPublic: true,
        memberEditUnlocked: true,
      );

      expect(
        ShiftAssignmentAccessPolicy.canEditApprovedAssignment(
          teamAssignment,
          currentUserId: 'user-1',
          canManageAssignment: false,
        ),
        isTrue,
      );
      expect(
        ShiftAssignmentAccessPolicy.canEditApprovedAssignment(
          personalAssignment,
          currentUserId: 'user-1',
          canManageAssignment: false,
        ),
        isFalse,
      );
    });

    test('treats blank team ids as personal scope', () {
      final assignment = buildAssignment(
        id: 'shift-5',
        userId: 'user-1',
        teamId: '   ',
        isPublic: true,
      );

      expect(ShiftAssignmentAccessPolicy.hasTeamScope(assignment), isFalse);
      expect(
        ShiftAssignmentAccessPolicy.canManageAssignment(
          assignment,
          currentUserId: 'user-1',
          manageableTeamIds: const <String>[],
        ),
        isTrue,
      );
    });
  });
}
