import 'package:intl/intl.dart';
import 'package:note_sondage/core/export/report_table_data.dart';
import 'package:note_sondage/feature/clocking/domain/entities/clocking_record_entity.dart';

/// Colonne del report timbrature, nell'ordine predefinito.
enum ClockingReportColumn {
  date,
  user,

  /// Email dell'utente: solo nell'esportazione, spenta di default.
  account,
  status,
  clockIn,
  clockOut,

  /// Uscita − entrata (lordo, senza togliere la pausa): solo
  /// nell'esportazione, spenta di default.
  duration,
  worked,
  breakTime,
  note;

  /// Colonne che l'utente deve attivare a mano.
  bool get isOptional =>
      this == ClockingReportColumn.account ||
      this == ClockingReportColumn.duration;

  /// Colonne incluse in un'esportazione se l'utente non cambia la selezione.
  static List<ClockingReportColumn> get defaultExport =>
      values.where((column) => !column.isOptional).toList(growable: false);
}

/// Uscita − entrata di un record, o `null` se non e' calcolabile (assenze di
/// giornata intera, timbratura ancora aperta, orari incoerenti).
Duration? clockingSpan(ClockingRecordEntity record) {
  if (record.isFullDayAbsence) {
    return null;
  }
  final clockIn = record.clockInTime;
  final clockOut = record.clockOutTime;
  if (clockIn == null || clockOut == null || clockOut.isBefore(clockIn)) {
    return null;
  }
  return clockOut.difference(clockIn);
}

/// Intestazioni e righe del report, nell'ordine delle [columns], cosi' PDF,
/// CSV ed Excel mostrano gli stessi dati.
ReportTableData buildClockingReportTable({
  required List<ClockingRecordEntity> records,
  required List<ClockingReportColumn> columns,
  required Map<ClockingReportColumn, String> headerByColumn,
  required String Function(ClockingStatus status) statusLabelOf,
  Map<String, String> emailByUserId = const {},
  int? maxNoteLength,
}) {
  final dateFormat = DateFormat('dd/MM/yyyy');

  String value(ClockingReportColumn column, ClockingRecordEntity record) {
    switch (column) {
      case ClockingReportColumn.date:
        return dateFormat.format(record.date);
      case ClockingReportColumn.user:
        return record.userName;
      case ClockingReportColumn.account:
        return emailByUserId[record.userId]?.trim() ?? '';
      case ClockingReportColumn.status:
        return statusLabelOf(record.status);
      case ClockingReportColumn.clockIn:
        return record.clockInFormatted;
      case ClockingReportColumn.clockOut:
        return record.clockOutFormatted;
      case ClockingReportColumn.duration:
        final span = clockingSpan(record);
        return span == null ? '' : formatReportDuration(span);
      case ClockingReportColumn.worked:
        return record.timeWorkedFormatted;
      case ClockingReportColumn.breakTime:
        return record.breakWorkedFormatted;
      case ClockingReportColumn.note:
        return _note(record.note, maxNoteLength);
    }
  }

  return ReportTableData(
    headers: [for (final column in columns) headerByColumn[column]!],
    rows: [
      for (final record in records)
        [for (final column in columns) value(column, record)],
    ],
  );
}

String _note(String? note, int? maxLength) {
  if (note == null) return '';
  final normalized = note.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (maxLength == null || normalized.length <= maxLength) return normalized;
  return '${normalized.substring(0, maxLength - 3)}...';
}
