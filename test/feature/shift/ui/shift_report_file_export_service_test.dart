import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_test/flutter_test.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_assignment_entity.dart';
import 'package:note_sondage/feature/shift/ui/utils/shift_report_file_export_service.dart';
import 'package:note_sondage/feature/shift/ui/utils/shift_report_table_data.dart';

void main() {
  const data = ShiftReportTableData(
    headers: ['Date', 'Note'],
    rows: [
      ['01/10/2026', 'Ciao; "mondo"\nriga 2'],
      ['02/10/2026', '=SUM(A1)'],
      ['03/10/2026', 'Café <&>'],
    ],
  );

  test('CSV uses BOM, semicolons, quoting and formula protection', () {
    final bytes = ShiftReportFileExportService.buildCsv(data);
    expect(bytes.take(3), [0xEF, 0xBB, 0xBF]);
    final text = utf8.decode(bytes);
    final lines = text.split('\r\n');
    expect(lines.first, 'Date;Note');
    expect(text, contains('"Ciao; ""mondo""\nriga 2"'));
    expect(text, contains("'=SUM(A1)"));
    expect(text, contains('Café <&>'));
  });

  test('XLSX is a valid zip with escaped cells and bold header', () {
    final bytes = ShiftReportFileExportService.buildXlsx(
      data,
      sheetName: 'Rapport: équipe/1',
    );
    final archive = ZipDecoder().decodeBytes(bytes);
    final names = archive.files.map((f) => f.name).toSet();
    expect(
      names,
      containsAll([
        '[Content_Types].xml',
        '_rels/.rels',
        'xl/workbook.xml',
        'xl/_rels/workbook.xml.rels',
        'xl/styles.xml',
        'xl/worksheets/sheet1.xml',
      ]),
    );
    String read(String name) =>
        utf8.decode(archive.findFile(name)!.content as List<int>);
    final sheet = read('xl/worksheets/sheet1.xml');
    expect(sheet, contains('r="A1"'));
    expect(sheet, contains('s="1"'));
    expect(sheet, contains('r="B4"'));
    expect(sheet, contains('Café &lt;&amp;&gt;'));
    expect(read('xl/workbook.xml'), contains('name="Rapport  équipe 1"'));
  });

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
}
