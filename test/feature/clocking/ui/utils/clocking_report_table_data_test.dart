import 'package:flutter_test/flutter_test.dart';
import 'package:note_sondage/feature/clocking/domain/entities/clocking_record_entity.dart';
import 'package:note_sondage/feature/clocking/ui/utils/clocking_report_table_data.dart';

ClockingRecordEntity _record({
  String id = '1',
  String userId = 'u1',
  String userName = 'arth juni',
  DateTime? clockIn,
  DateTime? clockOut,
  Duration? worked,
  int? breakMinutes,
  ClockingStatus status = ClockingStatus.committed,
  String? note,
}) => ClockingRecordEntity(
  id: id,
  userId: userId,
  userName: userName,
  teamName: 'team_test',
  clockInTime: clockIn,
  clockOutTime: clockOut,
  timeWorked: worked,
  totalBreakMinutes: breakMinutes,
  status: status,
  date: DateTime(2026, 10, 14),
  note: note,
);

const _headers = {
  ClockingReportColumn.date: 'Date',
  ClockingReportColumn.user: 'User',
  ClockingReportColumn.account: 'Account',
  ClockingReportColumn.status: 'Status',
  ClockingReportColumn.clockIn: 'In',
  ClockingReportColumn.clockOut: 'Out',
  ClockingReportColumn.duration: 'Duration',
  ClockingReportColumn.worked: 'Worked',
  ClockingReportColumn.breakTime: 'Break',
  ClockingReportColumn.note: 'Note',
};

void main() {
  test('account and duration are off by default but still exportable', () {
    expect(
      ClockingReportColumn.defaultExport,
      isNot(
        anyOf(
          contains(ClockingReportColumn.account),
          contains(ClockingReportColumn.duration),
        ),
      ),
    );
    expect(ClockingReportColumn.defaultExport.length, 8);
    expect(ClockingReportColumn.values.length, 10);
  });

  test('duration is clock-out minus clock-in, empty when not computable', () {
    final table = buildClockingReportTable(
      records: [
        _record(
          clockIn: DateTime(2026, 10, 14, 8, 15),
          clockOut: DateTime(2026, 10, 14, 17, 0),
        ),
        // Still open: no clock-out yet.
        _record(id: '2', clockIn: DateTime(2026, 10, 14, 8, 15)),
        // Inconsistent times.
        _record(
          id: '3',
          clockIn: DateTime(2026, 10, 14, 9, 0),
          clockOut: DateTime(2026, 10, 14, 8, 0),
        ),
        // Full-day absence never has a duration.
        _record(
          id: '4',
          status: ClockingStatus.vacation,
          clockIn: DateTime(2026, 10, 14, 0, 0),
          clockOut: DateTime(2026, 10, 14, 23, 0),
        ),
      ],
      columns: const [ClockingReportColumn.duration],
      headerByColumn: _headers,
      statusLabelOf: (s) => s.name,
    );
    expect(table.headers, ['Duration']);
    expect(table.rows.map((r) => r.single), ['8h 45m', '', '', '']);
  });

  test('keeps the requested column order and resolves account e-mails', () {
    final table = buildClockingReportTable(
      records: [
        _record(
          clockIn: DateTime(2026, 10, 14, 0, 15),
          clockOut: DateTime(2026, 10, 14, 0, 15),
          worked: const Duration(minutes: 1),
          breakMinutes: 0,
          note: '  test  ',
        ),
        _record(id: '2', userId: 'u2', userName: 'Anna'),
      ],
      columns: const [
        ClockingReportColumn.account,
        ClockingReportColumn.status,
        ClockingReportColumn.date,
        ClockingReportColumn.worked,
        ClockingReportColumn.note,
      ],
      headerByColumn: _headers,
      statusLabelOf: (s) => 'S:${s.name}',
      emailByUserId: const {'u1': ' arth@example.com '},
    );
    expect(table.headers, ['Account', 'Status', 'Date', 'Worked', 'Note']);
    expect(table.rows.first, [
      'arth@example.com',
      'S:committed',
      '14/10/2026',
      '0h 1m',
      'test',
    ]);
    // Unknown user: empty e-mail, not a crash.
    expect(table.rows[1].first, '');
  });

  test('notes are only shortened when a limit is given', () {
    final long = 'x' * 100;
    final shortened = buildClockingReportTable(
      records: [_record(note: long)],
      columns: const [ClockingReportColumn.note],
      headerByColumn: _headers,
      statusLabelOf: (s) => s.name,
      maxNoteLength: 60,
    );
    final full = buildClockingReportTable(
      records: [_record(note: long)],
      columns: const [ClockingReportColumn.note],
      headerByColumn: _headers,
      statusLabelOf: (s) => s.name,
    );
    expect(shortened.rows.single.single.length, 60);
    expect(shortened.rows.single.single, endsWith('...'));
    expect(full.rows.single.single, long);
  });
}
