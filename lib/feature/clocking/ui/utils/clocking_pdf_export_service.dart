import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:note_sondage/core/export/report_table_data.dart';
import 'package:note_sondage/feature/clocking/ui/utils/clocking_report_table_data.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ClockingPdfExportService {
  const ClockingPdfExportService._();

  /// [filters] sono le coppie etichetta/valore mostrate sotto il titolo.
  static Future<void> exportCurrentView({
    required ReportTableData table,
    required List<ClockingReportColumn> columns,
    required String teamName,
    required String title,
    required String teamLabel,
    required String generatedAtLabel,
    required List<MapEntry<String, String>> filters,
  }) async {
    final document = pw.Document(title: 'Clocking $teamName');
    final now = DateTime.now();
    final dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
    final compactDateTimeFormat = DateFormat('yyyyMMdd_HHmm');
    final hasFlexColumn = columns.contains(ClockingReportColumn.note);

    pw.TableColumnWidth widthFor(ClockingReportColumn column) {
      switch (column) {
        case ClockingReportColumn.date:
          return const pw.FixedColumnWidth(56);
        case ClockingReportColumn.user:
          return hasFlexColumn
              ? const pw.FixedColumnWidth(90)
              : const pw.FlexColumnWidth(1);
        case ClockingReportColumn.account:
          return const pw.FixedColumnWidth(120);
        case ClockingReportColumn.status:
          return const pw.FixedColumnWidth(80);
        case ClockingReportColumn.clockIn:
        case ClockingReportColumn.clockOut:
        case ClockingReportColumn.worked:
        case ClockingReportColumn.breakTime:
          return const pw.FixedColumnWidth(56);
        case ClockingReportColumn.duration:
          return const pw.FixedColumnWidth(76);
        case ClockingReportColumn.note:
          return const pw.FlexColumnWidth(2);
      }
    }

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 12),
            child: pw.Column(
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
                pw.Text(
                  '$teamLabel: $teamName',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.Text(
                  '$generatedAtLabel: ${dateTimeFormat.format(now)}',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.SizedBox(height: 10),
                pw.Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final filter in filters)
                      _filterBadge(filter.key, filter.value),
                  ],
                ),
              ],
            ),
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
              for (var i = 0; i < columns.length; i++) i: widthFor(columns[i]),
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
        'clocking_${normalizedTeamName.isEmpty ? 'team' : normalizedTeamName}_${compactDateTimeFormat.format(now)}.pdf';

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

  /// Intervallo di date nel formato `dd/MM/yyyy` (o un solo giorno).
  static String formatDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final normalizedStart = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );
    final normalizedEnd = DateTime(endDate.year, endDate.month, endDate.day);
    if (normalizedStart == normalizedEnd) {
      return dateFormat.format(normalizedStart);
    }
    return '${dateFormat.format(normalizedStart)} - ${dateFormat.format(normalizedEnd)}';
  }
}
