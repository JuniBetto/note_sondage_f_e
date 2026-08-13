import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_assignment_entity.dart';
import 'package:note_sondage/feature/shift/ui/utils/shift_assignment_day_visibility.dart';

void main() {
  ShiftAssignmentEntity buildAssignment({
    required String id,
    required DateTime shiftDate,
    required bool overnight,
  }) {
    return ShiftAssignmentEntity(
      id: id,
      userId: 'user-1',
      userName: 'Mario Rossi',
      shiftDate: shiftDate,
      teamId: null,
      teamShiftGroupId: null,
      profileId: null,
      profileName: 'Turno',
      profileColor: '#00AAFF',
      startTime: const TimeOfDay(hour: 22, minute: 0),
      endTime: const TimeOfDay(hour: 6, minute: 0),
      overnight: overnight,
      note: null,
      alarmOffsets: const <int>[],
      isPublic: false,
      memberEditUnlocked: false,
      memberChangeRequestPending: false,
    );
  }

  test('overnight assignment is visible on its start day and next day', () {
    final assignment = buildAssignment(
      id: 'assignment-1',
      shiftDate: DateTime(2026, 8, 23),
      overnight: true,
    );

    expect(
      isAssignmentVisibleOnDate(assignment, DateTime(2026, 8, 23)),
      isTrue,
    );
    expect(
      isAssignmentVisibleOnDate(assignment, DateTime(2026, 8, 24)),
      isTrue,
    );
    expect(
      isAssignmentVisibleOnDate(assignment, DateTime(2026, 8, 25)),
      isFalse,
    );
  });

  test('same-day assignment is only visible on its shift date', () {
    final assignment = buildAssignment(
      id: 'assignment-2',
      shiftDate: DateTime(2026, 8, 23),
      overnight: false,
    );

    expect(
      isAssignmentVisibleOnDate(assignment, DateTime(2026, 8, 23)),
      isTrue,
    );
    expect(
      isAssignmentVisibleOnDate(assignment, DateTime(2026, 8, 24)),
      isFalse,
    );
  });
}
