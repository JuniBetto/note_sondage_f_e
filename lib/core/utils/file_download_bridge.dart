import 'dart:typed_data';

import 'file_download_bridge_stub.dart'
    if (dart.library.html) 'file_download_bridge_web.dart';

abstract class FileDownloadBridge {
  Future<bool> saveBytes({required Uint8List bytes, String? fileName});
}

FileDownloadBridge createFileDownloadBridge() => createFileDownloadBridgeImpl();
