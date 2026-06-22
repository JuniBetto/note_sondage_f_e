import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'file_download_bridge.dart';

class _WebFileDownloadBridge implements FileDownloadBridge {
  @override
  Future<bool> saveBytes({required Uint8List bytes, String? fileName}) async {
    if (bytes.isEmpty) {
      return false;
    }
    final blob = web.Blob(
      [bytes.toJS].toJS,
      web.BlobPropertyBag(type: 'application/octet-stream'),
    );
    final objectUrl = web.URL.createObjectURL(blob);
    final anchor = web.HTMLAnchorElement()
      ..href = objectUrl
      ..target = '_blank'
      ..rel = 'noopener';

    final sanitizedFileName = fileName?.trim();
    if (sanitizedFileName != null && sanitizedFileName.isNotEmpty) {
      anchor.download = sanitizedFileName;
    }

    final parent = web.document.body ?? web.document.documentElement;
    if (parent == null) {
      return false;
    }

    parent.append(anchor);
    anchor.click();
    anchor.remove();
    web.URL.revokeObjectURL(objectUrl);
    return true;
  }
}

FileDownloadBridge createFileDownloadBridgeImpl() => _WebFileDownloadBridge();
