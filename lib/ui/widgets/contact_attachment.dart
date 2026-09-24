import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// Client-side checks are for immediate feedback; the server validates again.
class ContactAttachment {
  const ContactAttachment(this.name, this.contentType, this.bytes);

  static const maxBytes = 5000000;
  static const maxFiles = 5;
  static const types = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'pdf': 'application/pdf',
  };

  final String name;
  final String contentType;
  final Uint8List bytes;

  static Future<ContactAttachment> read(
    PlatformFile file, {
    required int remainingBytes,
  }) async {
    final extension = file.name.split('.').last.toLowerCase();
    final type = types[extension];
    if (type == null) throw const FormatException('type');
    if (file.size <= 0 ||
        file.name.length > 180 ||
        file.name.startsWith('.') ||
        file.name.contains('..') ||
        !RegExp(r'^[\p{L}\p{N} _().-]+$', unicode: true).hasMatch(file.name)) {
      throw const FormatException('invalid');
    }
    if (file.size > remainingBytes) throw const FormatException('size');
    final builder = BytesBuilder(copy: false);
    if (file.readStream != null) {
      await for (final chunk in file.readStream!) {
        if (builder.length + chunk.length > remainingBytes) {
          throw const FormatException('size');
        }
        builder.add(chunk);
      }
    } else if (file.bytes != null) {
      if (file.bytes!.length > remainingBytes) {
        throw const FormatException('size');
      }
      builder.add(file.bytes!);
    } else {
      throw const FormatException('invalid');
    }
    final bytes = builder.takeBytes();
    if (bytes.length != file.size) throw const FormatException('invalid');
    final signature = switch (extension) {
      'png' => [137, 80, 78, 71, 13, 10, 26, 10],
      'pdf' => [37, 80, 68, 70, 45],
      _ => [255, 216, 255],
    };
    if (bytes.length < signature.length ||
        Iterable<int>.generate(
          signature.length,
        ).any((i) => bytes[i] != signature[i])) {
      throw const FormatException('type');
    }
    return ContactAttachment(file.name, type, bytes);
  }
}
