import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:qr/qr.dart';

class TotpQrCode extends StatelessWidget {
  const TotpQrCode({
    super.key,
    required this.data,
    this.size = 180,
    this.foregroundColor = Colors.black,
    this.backgroundColor = Colors.white,
  });

  final String data;
  final double size;
  final Color foregroundColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final qrCode = QrCode.fromData(
      data: data,
      errorCorrectLevel: QrErrorCorrectLevel.M,
    );
    final qrImage = QrImage(qrCode);

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black12),
      ),
      child: CustomPaint(
        painter: _TotpQrPainter(
          image: qrImage,
          foregroundColor: foregroundColor,
          backgroundColor: backgroundColor,
        ),
      ),
    );
  }
}

class _TotpQrPainter extends CustomPainter {
  const _TotpQrPainter({
    required this.image,
    required this.foregroundColor,
    required this.backgroundColor,
  });

  final QrImage image;
  final Color foregroundColor;
  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()..color = backgroundColor;
    final foregroundPaint = Paint()..color = foregroundColor;
    final moduleCount = image.moduleCount;
    final cellSize = size.width / moduleCount;

    canvas.drawRect(Offset.zero & size, backgroundPaint);

    for (var row = 0; row < moduleCount; row++) {
      for (var col = 0; col < moduleCount; col++) {
        if (!image.isDark(row, col)) {
          continue;
        }
        canvas.drawRect(
          Rect.fromLTWH(col * cellSize, row * cellSize, cellSize, cellSize),
          foregroundPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TotpQrPainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.foregroundColor != foregroundColor ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
