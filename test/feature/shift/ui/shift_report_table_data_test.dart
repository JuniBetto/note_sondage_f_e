import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_test/flutter_test.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_assignment_entity.dart';
import 'package:note_sondage/feature/shift/ui/utils/shift_report_table_data.dart';

ShiftAssignmentEntity _assignment({
  String id = '1',
  String userId = 'u1',
  String? userName,
  TimeOfDay start = const TimeOfDay(hour: 9, minute: 0),
  TimeOfDay end = const TimeOfDay(hour: 18, minute: 0),
  bool overnight = false,
}) => ShiftAssignmentEntity(
  id: id,
  userId: userId,
  userName: userName,
  shiftDate: DateTime(2026, 8, 16),
  startTime: start,
  endTime: end,
  overnight: overnight,
  alarmOffsets: const [],
);

void main() {
  test('buildShiftReportTable keeps the requested column order', () {
    final table = buildShiftReportTable(
      assignments: const [],
      columns: const [ShiftReportColumn.note, ShiftReportColumn.date],
      headerByColumn: const {
        ShiftReportColumn.note: 'Note',
        ShiftReportColumn.date: 'Date',
      },
      teamLabel: 'Team',
      defaultProfileLabel: 'Shift',
      privateTypeLabel: 'Private',
    );
    expect(table.headers, ['Note', 'Date']);
    expect(table.rows, isEmpty);
  });

  test('account column resolves the e-mail from the user id', () {
    final table = buildShiftReportTable(
      assignments: [
        ShiftAssignmentEntity(
          id: '1',
          userId: 'u1',
          userName: 'arth',
          shiftDate: DateTime(2026, 8, 16),
          startTime: const TimeOfDay(hour: 9, minute: 0),
          endTime: const TimeOfDay(hour: 18, minute: 0),
          overnight: false,
          alarmOffsets: const [],
        ),
        ShiftAssignmentEntity(
          id: '2',
          userId: 'u2',
          shiftDate: DateTime(2026, 8, 17),
          startTime: const TimeOfDay(hour: 9, minute: 0),
          endTime: const TimeOfDay(hour: 18, minute: 0),
          overnight: false,
          alarmOffsets: const [],
        ),
      ],
      columns: const [ShiftReportColumn.user, ShiftReportColumn.account],
      headerByColumn: const {
        ShiftReportColumn.user: 'User',
        ShiftReportColumn.account: 'Account',
      },
      teamLabel: 'Team',
      defaultProfileLabel: 'Shift',
      privateTypeLabel: 'Private',
      emailByUserId: const {'u1': ' arth@example.com '},
    );
    expect(table.headers, ['User', 'Account']);
    expect(table.rows, [
      ['arth', 'arth@example.com'],
      ['u2', ''],
    ]);
  });

  test('account is excluded from the default export and the table', () {
    expect(
      ShiftReportColumn.defaultExport,
      isNot(contains(ShiftReportColumn.account)),
    );
    expect(ShiftReportColumn.account.isShownInTable, isFalse);
    expect(ShiftReportColumn.date.isShownInTable, isTrue);
  });

  test('duration column is off by default and follows the overnight rule', () {
    expect(
      ShiftReportColumn.defaultExport,
      isNot(contains(ShiftReportColumn.duration)),
    );
    expect(ShiftReportColumn.duration.isShownInTable, isFalse);

    final table = buildShiftReportTable(
      assignments: [
        _assignment(),
        _assignment(
          id: '2',
          start: const TimeOfDay(hour: 22, minute: 30),
          end: const TimeOfDay(hour: 6, minute: 0),
          overnight: true,
        ),
        _assignment(
          id: '3',
          start: const TimeOfDay(hour: 0, minute: 0),
          end: const TimeOfDay(hour: 0, minute: 0),
          overnight: true,
        ),
        _assignment(
          id: '4',
          start: const TimeOfDay(hour: 6, minute: 0),
          end: const TimeOfDay(hour: 7, minute: 0),
          overnight: true,
        ),
      ],
      columns: const [ShiftReportColumn.duration],
      headerByColumn: const {ShiftReportColumn.duration: 'Duration'},
      teamLabel: 'Team',
      defaultProfileLabel: 'Shift',
      privateTypeLabel: 'Private',
    );
    expect(table.rows.map((r) => r.single), [
      '9h 0m',
      '7h 30m',
      '24h 0m',
      '25h 0m',
    ]);
  });
}
