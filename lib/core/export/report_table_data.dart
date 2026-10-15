/// Formati di esportazione dei report.
enum ReportExportFormat { pdf, csv, excel }

/// Tabella pronta da esportare: intestazioni e righe di testo.
class ReportTableData {
  const ReportTableData({required this.headers, required this.rows});

  final List<String> headers;
  final List<List<String>> rows;
}

/// Durata nel formato usato dall'app, es. `8h 30m`.
String formatReportDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  return '${hours}h ${minutes}m';
}
