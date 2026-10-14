import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_assignment_entity.dart';
import 'package:note_sondage/feature/shift/ui/utils/shift_report_table_data.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ShiftReportPdfExportService {
  const ShiftReportPdfExportService._();

  static Future<void> exportCurrentView({
    required String teamName,
    required DateTime from,
    required DateTime to,
    required List<String> selectedUserNames,
    required List<ShiftAssignmentEntity> assignments,
    required String title,
    required String generatedAtLabel,
    required String teamLabel,
    required String periodLabel,
    required String usersLabel,
    required String shiftsLabel,
    required String allUsersLabel,
    required String dateColumn,
    required String userColumn,
    required String profileColumn,
    required String startColumn,
    required String endColumn,
    required String typeColumn,
    required String noteColumn,
    required String defaultProfileLabel,
    required String privateTypeLabel,
    required String accountColumn,
    Map<String, String> emailByUserId = const {},
    List<ShiftReportColumn>? columns,
  }) async {
    final exportColumns = columns == null || columns.isEmpty
        ? ShiftReportColumn.defaultExport
        : columns;
    final headerByColumn = <ShiftReportColumn, String>{
      ShiftReportColumn.date: dateColumn,
      ShiftReportColumn.user: userColumn,
      ShiftReportColumn.account: accountColumn,
      ShiftReportColumn.profile: profileColumn,
      ShiftReportColumn.start: startColumn,
      ShiftReportColumn.end: endColumn,
      ShiftReportColumn.type: typeColumn,
      ShiftReportColumn.note: noteColumn,
    };
    final hasFlexColumn = exportColumns.contains(ShiftReportColumn.note);
    pw.TableColumnWidth widthFor(ShiftReportColumn column) {
      switch (column) {
        case ShiftReportColumn.date:
          return const pw.FixedColumnWidth(64);
        case ShiftReportColumn.user:
          return hasFlexColumn
              ? const pw.FixedColumnWidth(96)
              : const pw.FlexColumnWidth(1);
        case ShiftReportColumn.account:
          return const pw.FixedColumnWidth(120);
        case ShiftReportColumn.profile:
          return const pw.FixedColumnWidth(92);
        case ShiftReportColumn.start:
        case ShiftReportColumn.end:
          return const pw.FixedColumnWidth(62);
        case ShiftReportColumn.type:
          return const pw.FixedColumnWidth(54);
        case ShiftReportColumn.note:
          return const pw.FlexColumnWidth(2);
      }
    }

    final table = buildShiftReportTable(
      assignments: assignments,
      columns: exportColumns,
      headerByColumn: headerByColumn,
      teamLabel: teamLabel,
      defaultProfileLabel: defaultProfileLabel,
      privateTypeLabel: privateTypeLabel,
      emailByUserId: emailByUserId,
      maxNoteLength: 60,
    );

    final document = pw.Document(title: 'Shift report $teamName');
    final now = DateTime.now();
    final dateFormat = DateFormat('dd/MM/yyyy');
    final dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
    final compactDateTimeFormat = DateFormat('yyyyMMdd_HHmm');

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text('$teamLabel: $teamName'),
              pw.Text('$generatedAtLabel: ${dateTimeFormat.format(now)}'),
              pw.SizedBox(height: 10),
              pw.Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _filterBadge(
                    periodLabel,
                    '${dateFormat.format(from)} - ${dateFormat.format(to)}',
                  ),
                  _filterBadge(
                    usersLabel,
                    selectedUserNames.isEmpty
                        ? allUsersLabel
                        : selectedUserNames.join(', '),
                  ),
                  _filterBadge(shiftsLabel, '${assignments.length}'),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
              fontSize: 10,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.blueGrey800,
            ),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 8,
            ),
            columnWidths: {
              for (var i = 0; i < exportColumns.length; i++)
                i: widthFor(exportColumns[i]),
            },
            headers: table.headers,
            data: table.rows,
          ),
        ],
      ),
    );

    final Uint8List bytes = await document.save();
    final normalizedTeamName = teamName
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    final filename =
        'shift_report_${normalizedTeamName.isEmpty ? 'team' : normalizedTeamName}_${compactDateTimeFormat.format(now)}.pdf';

    await Printing.sharePdf(bytes: bytes, filename: filename);
  }

  static pw.Widget _filterBadge(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(999),
        color: PdfColors.blue50,
      ),
      child: pw.Text(
        '$label: $value',
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blueGrey900,
        ),
      ),
    );
  }
}
