import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_assignment_entity.dart';
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
  }) async {
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
              0: const pw.FixedColumnWidth(64),
              1: const pw.FixedColumnWidth(96),
              2: const pw.FixedColumnWidth(92),
              3: const pw.FixedColumnWidth(62),
              4: const pw.FixedColumnWidth(62),
              5: const pw.FixedColumnWidth(54),
              6: const pw.FlexColumnWidth(2),
            },
            headers: [
              dateColumn,
              userColumn,
              profileColumn,
              startColumn,
              endColumn,
              typeColumn,
              noteColumn,
            ],
            data: assignments
                .map(
                  (assignment) => [
                    dateFormat.format(assignment.shiftDate),
                    _displayUserName(assignment),
                    assignment.profileName ?? defaultProfileLabel,
                    _formatTime(assignment.startTime),
                    _formatTime(assignment.endTime),
                    assignment.isPublic ? teamLabel : privateTypeLabel,
                    _compactNote(assignment.note),
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

  static String _displayUserName(ShiftAssignmentEntity assignment) {
    final name = assignment.userName?.trim();
    if (name != null && name.isNotEmpty) {
      return name;
    }
    return assignment.userId;
  }

  static String _formatTime(dynamic time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static String _compactNote(String? note) {
    if (note == null) return '';
    final normalized = note.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.length <= 60) return normalized;
    return '${normalized.substring(0, 57)}...';
  }
}
