import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'file_download_bridge.dart';

class _DefaultFileDownloadBridge implements FileDownloadBridge {
  @override
  Future<bool> saveBytes({required Uint8List bytes, String? fileName}) async {
    try {
      if (bytes.isEmpty) {
        return false;
      }
      final resolvedFileName = _resolveFileName(fileName);
      final savedPath = await _saveWithPicker(
        fileName: resolvedFileName,
        bytes: bytes,
      );
      if (savedPath != null && savedPath.trim().isNotEmpty) {
        return true;
      }

      final fallbackPath = await _saveInAppStorage(
        fileName: resolvedFileName,
        bytes: bytes,
      );
      return fallbackPath != null && fallbackPath.trim().isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<String?> _saveWithPicker({
    required String fileName,
    required Uint8List bytes,
  }) async {
    try {
      return await FilePicker.platform.saveFile(
        fileName: fileName,
        bytes: bytes,
      );
    } catch (_) {
      return null;
    }
  }

  Future<String?> _saveInAppStorage({
    required String fileName,
    required Uint8List bytes,
  }) async {
    try {
      final baseDirectory =
          await getDownloadsDirectory() ??
          await getApplicationDocumentsDirectory();
      final targetDirectory = Directory('${baseDirectory.path}/Chat');
      if (!await targetDirectory.exists()) {
        await targetDirectory.create(recursive: true);
      }

      final sanitizedFileName = fileName
          .replaceAll('\\', '_')
          .replaceAll('/', '_');
      final file = File('${targetDirectory.path}/$sanitizedFileName');
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } catch (_) {
      return null;
    }
  }

  String _resolveFileName(String? fileName) {
    final normalized = fileName?.trim();
    if (normalized != null && normalized.isNotEmpty) {
      return normalized;
    }
    return 'attachment';
  }
}

FileDownloadBridge createFileDownloadBridgeImpl() =>
    _DefaultFileDownloadBridge();
