import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:note_sondage/feature/clocking/domain/entities/clocking_record_entity.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ClockingPdfExportService {
  const ClockingPdfExportService._();

  static Future<void> exportCurrentView({
    required List<ClockingRecordEntity> records,
    required String teamName,
    required String searchQuery,
    required DateTime? selectedDate,
    required Set<ClockingStatus> selectedStatuses,
  }) async {
    final document = pw.Document(title: 'Clocking $teamName');
    final now = DateTime.now();
    final dateFormat = DateFormat('dd/MM/yyyy');
    final dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
    final compactDateTimeFormat = DateFormat('yyyyMMdd_HHmm');

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
                  'Report timbrature team',
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  'Team: $teamName',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.Text(
                  'Generato il: ${dateTimeFormat.format(now)}',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.SizedBox(height: 10),
                pw.Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _filterBadge('Ricerca', searchQuery.isEmpty ? 'Tutte' : searchQuery),
                    _filterBadge(
                      'Data',
                      selectedDate == null ? 'Tutte' : dateFormat.format(selectedDate),
                    ),
                    _filterBadge(
                      'Stato',
                      selectedStatuses.isEmpty
                          ? 'Tutti'
                          : selectedStatuses.map(_statusLabel).join(', '),
                    ),
                    _filterBadge('Record', '${records.length}'),
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
              0: const pw.FixedColumnWidth(56),
              1: const pw.FixedColumnWidth(90),
              2: const pw.FixedColumnWidth(80),
              3: const pw.FixedColumnWidth(56),
              4: const pw.FixedColumnWidth(56),
              5: const pw.FixedColumnWidth(56),
              6: const pw.FixedColumnWidth(56),
              7: const pw.FlexColumnWidth(2),
            },
            headers: const [
              'Data',
              'Utente',
              'Stato',
              'Clock-in',
              'Clock-out',
              'Worked',
              'Break',
              'Nota',
            ],
            data: records
                .map(
                  (record) => [
                    dateFormat.format(record.date),
                    record.userName,
                    record.statusLabel,
                    record.clockInFormatted,
                    record.clockOutFormatted,
                    record.timeWorkedFormatted,
                    record.breakWorkedFormatted,
                    _compactNote(record.note),
                  ],
                )
                .toList(),
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

  static String _statusLabel(ClockingStatus status) {
    switch (status) {
      case ClockingStatus.committed:
        return 'Committed';
      case ClockingStatus.decommitted:
        return 'Decommitted';
      case ClockingStatus.clockedIn:
        return 'Clocked in';
      case ClockingStatus.onBreak:
        return 'On break';
      case ClockingStatus.absent:
        return 'Absent';
      case ClockingStatus.late:
        return 'Late';
      case ClockingStatus.vacation:
        return 'Vacation';
      case ClockingStatus.permission:
        return 'Permission';
    }
  }

  static String _compactNote(String? note) {
    if (note == null) return '';
    final normalized = note.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.length <= 60) return normalized;
    return '${normalized.substring(0, 57)}...';
  }
}
