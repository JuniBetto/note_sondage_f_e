import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_sondage/core/export/report_table_data.dart';
import 'package:note_sondage/core/export/report_table_file_export_service.dart';

void main() {
  const data = ReportTableData(
    headers: ['Date', 'Note'],
    rows: [
      ['01/10/2026', 'Ciao; "mondo"\nriga 2'],
      ['02/10/2026', '=SUM(A1)'],
      ['03/10/2026', 'Café <&>'],
    ],
  );

  test('CSV uses BOM, semicolons, quoting and formula protection', () {
    final bytes = ReportTableFileExportService.buildCsv(data);
    expect(bytes.take(3), [0xEF, 0xBB, 0xBF]);
    final text = utf8.decode(bytes);
    final lines = text.split('\r\n');
    expect(lines.first, 'Date;Note');
    expect(text, contains('"Ciao; ""mondo""\nriga 2"'));
    expect(text, contains("'=SUM(A1)"));
    expect(text, contains('Café <&>'));
  });

  test('XLSX is a valid zip with escaped cells and bold header', () {
    final bytes = ReportTableFileExportService.buildXlsx(
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

  test('formatReportDuration uses the app format', () {
    expect(
      formatReportDuration(const Duration(hours: 8, minutes: 30)),
      '8h 30m',
    );
    expect(formatReportDuration(Duration.zero), '0h 0m');
    expect(
      formatReportDuration(const Duration(hours: 26, minutes: 5)),
      '26h 5m',
    );
  });
}
