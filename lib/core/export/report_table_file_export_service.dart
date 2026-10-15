import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:intl/intl.dart';
import 'package:note_sondage/core/utils/file_download_bridge.dart';
import 'package:note_sondage/core/export/report_table_data.dart';

/// Esporta un report tabellare come CSV o Excel (.xlsx).
class ReportTableFileExportService {
  const ReportTableFileExportService._();

  /// CSV in UTF-8 con BOM e separatore `;`, cosi' Excel (IT/FR/ES) lo apre
  /// direttamente con le colonne separate e gli accenti corretti.
  static Uint8List buildCsv(ReportTableData data) {
    final buffer = StringBuffer('﻿');
    void writeRow(List<String> cells) {
      buffer
        ..write(cells.map(_csvCell).join(';'))
        ..write('\r\n');
    }

    writeRow(data.headers);
    data.rows.forEach(writeRow);
    return Uint8List.fromList(utf8.encode(buffer.toString()));
  }

  static String _csvCell(String value) {
    var cell = value;
    // Evita che Excel interpreti il contenuto come una formula.
    if (cell.isNotEmpty && '=+-@\t\r'.contains(cell[0])) {
      cell = "'$cell";
    }
    if (cell.contains(RegExp(r'[;"\r\n]'))) {
      cell = '"${cell.replaceAll('"', '""')}"';
    }
    return cell;
  }

  /// Foglio Excel minimale: intestazione in grassetto, colonne con larghezza
  /// adattata al contenuto e testo salvato come stringa (mai come formula).
  static Uint8List buildXlsx(
    ReportTableData data, {
    String sheetName = 'Report',
  }) {
    final widths = List<double>.generate(data.headers.length, (i) {
      var longest = data.headers[i].length;
      for (final row in data.rows) {
        if (row[i].length > longest) longest = row[i].length;
      }
      return (longest + 3).clamp(8, 60).toDouble();
    });

    final sheet = StringBuffer(
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
      '<sheetViews><sheetView workbookViewId="0">'
      '<pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" state="frozen"/>'
      '</sheetView></sheetViews>'
      '<cols>',
    );
    for (var i = 0; i < widths.length; i++) {
      sheet.write(
        '<col min="${i + 1}" max="${i + 1}" width="${widths[i]}" customWidth="1"/>',
      );
    }
    sheet.write('</cols><sheetData>');

    void writeRow(int rowIndex, List<String> cells, {required bool header}) {
      sheet.write('<row r="$rowIndex">');
      for (var i = 0; i < cells.length; i++) {
        final ref = '${_columnName(i)}$rowIndex';
        sheet.write(
          '<c r="$ref" t="inlineStr"${header ? ' s="1"' : ''}>'
          '<is><t xml:space="preserve">${_xml(cells[i])}</t></is></c>',
        );
      }
      sheet.write('</row>');
    }

    writeRow(1, data.headers, header: true);
    for (var r = 0; r < data.rows.length; r++) {
      writeRow(r + 2, data.rows[r], header: false);
    }
    sheet.write('</sheetData></worksheet>');

    const styles =
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
        '<fonts count="2"><font><sz val="11"/><name val="Calibri"/></font>'
        '<font><b/><sz val="11"/><name val="Calibri"/></font></fonts>'
        '<fills count="2"><fill><patternFill patternType="none"/></fill>'
        '<fill><patternFill patternType="gray125"/></fill></fills>'
        '<borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>'
        '<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>'
        '<cellXfs count="2"><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>'
        '<xf numFmtId="0" fontId="1" fillId="0" borderId="0" xfId="0" applyFont="1"/></cellXfs>'
        '</styleSheet>';

    final files = <String, String>{
      '[Content_Types].xml':
          '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
          '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
          '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
          '<Default Extension="xml" ContentType="application/xml"/>'
          '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
          '<Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>'
          '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>'
          '</Types>',
      '_rels/.rels':
          '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
          '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
          '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>'
          '</Relationships>',
      'xl/workbook.xml':
          '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
          '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
          'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
          '<sheets><sheet name="${_xml(_sheetName(sheetName))}" sheetId="1" r:id="rId1"/></sheets>'
          '</workbook>',
      'xl/_rels/workbook.xml.rels':
          '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
          '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
          '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>'
          '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>'
          '</Relationships>',
      'xl/styles.xml': styles,
      'xl/worksheets/sheet1.xml': sheet.toString(),
    };

    final archive = Archive();
    files.forEach((name, content) {
      final bytes = utf8.encode(content);
      archive.addFile(ArchiveFile(name, bytes.length, bytes));
    });
    return Uint8List.fromList(ZipEncoder().encode(archive));
  }

  /// Nomi di foglio Excel: max 31 caratteri e senza `\ / ? * [ ] :`.
  static String _sheetName(String name) {
    final cleaned = name.replaceAll(RegExp(r'[\\/?*\[\]:]'), ' ').trim();
    if (cleaned.isEmpty) return 'Report';
    return cleaned.length > 31 ? cleaned.substring(0, 31) : cleaned;
  }

  static String _columnName(int index) {
    var n = index;
    var name = '';
    do {
      name = String.fromCharCode(65 + n % 26) + name;
      n = n ~/ 26 - 1;
    } while (n >= 0);
    return name;
  }

  static String _xml(String value) {
    final sanitized = value.replaceAll(
      RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'),
      '',
    );
    return sanitized
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;');
  }

  /// Genera e salva il file. Lancia un'eccezione se il salvataggio fallisce.
  static Future<void> export({
    required ReportExportFormat format,
    required ReportTableData data,
    required String teamName,
    required String filePrefix,
    String? sheetName,
  }) async {
    assert(format != ReportExportFormat.pdf);
    final isCsv = format == ReportExportFormat.csv;
    final bytes = isCsv
        ? buildCsv(data)
        : buildXlsx(data, sheetName: sheetName ?? 'Report');
    final normalizedTeamName = teamName
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    final stamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final fileName =
        '${filePrefix}_${normalizedTeamName.isEmpty ? 'team' : normalizedTeamName}_$stamp.${isCsv ? 'csv' : 'xlsx'}';

    final saved = await createFileDownloadBridge().saveBytes(
      bytes: bytes,
      fileName: fileName,
    );
    if (!saved) {
      throw Exception('Unable to save $fileName');
    }
  }
}
