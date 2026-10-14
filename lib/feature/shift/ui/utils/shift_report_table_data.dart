import 'package:intl/intl.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_assignment_entity.dart';

/// Colonne del report turni, nell'ordine predefinito.
enum ShiftReportColumn {
  date,
  user,

  /// Email dell'utente: disponibile solo nell'esportazione, mai in tabella.
  account,
  profile,
  start,
  end,
  type,
  note;

  /// Colonne mostrate nella tabella a schermo.
  bool get isShownInTable => this != ShiftReportColumn.account;

  /// Colonne incluse in un'esportazione se l'utente non cambia la selezione.
  static List<ShiftReportColumn> get defaultExport => values
      .where((column) => column != ShiftReportColumn.account)
      .toList(growable: false);
}

/// Formati di esportazione del report turni.
enum ShiftReportExportFormat { pdf, csv, excel }

class ShiftReportTableData {
  const ShiftReportTableData({required this.headers, required this.rows});

  final List<String> headers;
  final List<List<String>> rows;
}

/// Costruisce intestazioni e righe del report, nell'ordine delle [columns],
/// cosi' PDF, CSV ed Excel mostrano gli stessi dati.
ShiftReportTableData buildShiftReportTable({
  required List<ShiftAssignmentEntity> assignments,
  required List<ShiftReportColumn> columns,
  required Map<ShiftReportColumn, String> headerByColumn,
  required String teamLabel,
  required String defaultProfileLabel,
  required String privateTypeLabel,
  Map<String, String> emailByUserId = const {},
  int? maxNoteLength,
}) {
  final dateFormat = DateFormat('dd/MM/yyyy');

  String value(ShiftReportColumn column, ShiftAssignmentEntity assignment) {
    switch (column) {
      case ShiftReportColumn.date:
        return dateFormat.format(assignment.shiftDate);
      case ShiftReportColumn.user:
        final name = assignment.userName?.trim();
        return name != null && name.isNotEmpty ? name : assignment.userId;
      case ShiftReportColumn.account:
        return emailByUserId[assignment.userId]?.trim() ?? '';
      case ShiftReportColumn.profile:
        return assignment.profileName ?? defaultProfileLabel;
      case ShiftReportColumn.start:
        return _formatTime(
          assignment.startTime.hour,
          assignment.startTime.minute,
        );
      case ShiftReportColumn.end:
        return _formatTime(assignment.endTime.hour, assignment.endTime.minute);
      case ShiftReportColumn.type:
        return assignment.isPublic ? teamLabel : privateTypeLabel;
      case ShiftReportColumn.note:
        return _note(assignment.note, maxNoteLength);
    }
  }

  return ShiftReportTableData(
    headers: [for (final column in columns) headerByColumn[column]!],
    rows: [
      for (final assignment in assignments)
        [for (final column in columns) value(column, assignment)],
    ],
  );
}

String _formatTime(int hour, int minute) =>
    '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

String _note(String? note, int? maxLength) {
  if (note == null) return '';
  final normalized = note.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (maxLength == null || normalized.length <= maxLength) return normalized;
  return '${normalized.substring(0, maxLength - 3)}...';
}
