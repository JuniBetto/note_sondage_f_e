import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_sondage/ui/widgets/contact_attachment.dart';

void main() {
  const png = [137, 80, 78, 71, 13, 10, 26, 10];

  test(
    'reads a permitted file in chunks within the remaining budget',
    () async {
      final file = PlatformFile(
        name: 'screenshot.PNG',
        size: png.length,
        readStream: Stream.fromIterable([png.sublist(0, 4), png.sublist(4)]),
      );
      final attachment = await ContactAttachment.read(file, remainingBytes: 8);
      expect(attachment.contentType, 'image/png');
      expect(attachment.bytes, png);
    },
  );

  test(
    'rejects files above the remaining combined size before reading',
    () async {
      final file = PlatformFile(name: 'photo.png', size: 9);
      await expectLater(
        ContactAttachment.read(file, remainingBytes: 8),
        throwsA(isA<FormatException>()),
      );
    },
  );

  test('bounds actual stream data even when declared size is false', () async {
    final file = PlatformFile(
      name: 'photo.png',
      size: 8,
      readStream: Stream.value([...png, 0]),
    );
    await expectLater(
      ContactAttachment.read(file, remainingBytes: 8),
      throwsA(isA<FormatException>()),
    );
  });

  test(
    'rejects unsupported formats, unsafe names and mismatched signatures',
    () async {
      for (final name in [
        'photo.svg',
        'photo.exe',
        'photo.jpg',
        '../photo.png',
        'photo\n.png',
      ]) {
        final file = PlatformFile(
          name: name,
          size: png.length,
          bytes: Uint8List.fromList(png),
        );
        await expectLater(
          ContactAttachment.read(file, remainingBytes: 100),
          throwsA(isA<FormatException>()),
        );
      }
    },
  );

  test('rejects empty files and truncated reads', () async {
    for (final size in [0, 10]) {
      final file = PlatformFile(
        name: 'photo.png',
        size: size,
        bytes: Uint8List.fromList(png),
      );
      await expectLater(
        ContactAttachment.read(file, remainingBytes: 100),
        throwsA(isA<FormatException>()),
      );
    }
  });
}
