import 'package:intl/intl.dart';
import 'package:note_sondage/core/export/report_table_data.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_assignment_entity.dart';
import 'package:note_sondage/feature/shift/ui/utils/shift_duration.dart';

/// Colonne del report turni, nell'ordine predefinito.
enum ShiftReportColumn {
  date,
  user,

  /// Email dell'utente: disponibile solo nell'esportazione, mai in tabella.
  account,
  profile,
  start,
  end,

  /// Fine − inizio: solo nell'esportazione, spenta di default.
  duration,
  type,
  note;

  /// Colonne mostrate nella tabella a schermo.
  bool get isShownInTable =>
      this != ShiftReportColumn.account && this != ShiftReportColumn.duration;

  /// Colonne incluse in un'esportazione se l'utente non cambia la selezione.
  static List<ShiftReportColumn> get defaultExport =>
      values.where((column) => column.isShownInTable).toList(growable: false);
}

/// Costruisce intestazioni e righe del report, nell'ordine delle [columns],
/// cosi' PDF, CSV ed Excel mostrano gli stessi dati.
ReportTableData buildShiftReportTable({
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
      case ShiftReportColumn.duration:
        return formatReportDuration(shiftDuration(assignment));
      case ShiftReportColumn.type:
        return assignment.isPublic ? teamLabel : privateTypeLabel;
      case ShiftReportColumn.note:
        return _note(assignment.note, maxNoteLength);
    }
  }

  return ReportTableData(
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

/// Durata di un turno (vedi [shiftDurationFor]).
Duration shiftDuration(ShiftAssignmentEntity assignment) => shiftDurationFor(
  start: assignment.startTime,
  end: assignment.endTime,
  overnight: assignment.overnight,
);
