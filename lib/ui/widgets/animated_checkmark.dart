import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:note_sondage/theme/extensions/theme_extensions.dart';

/// A reusable success confirmation: a ring that draws itself, followed by a
/// checkmark that traces in, then a small elastic settle. Used everywhere a
/// request needs a positive, celebratory confirmation (see [AppSnackBar]'s
/// success overlay).
class AnimatedCheckmark extends StatefulWidget {
  const AnimatedCheckmark({
    super.key,
    this.size = 64,
    this.color,
    this.trackColor,
    this.strokeWidth,
  });

  final double size;
  final Color? color;
  final Color? trackColor;
  final double? strokeWidth;

  @override
  State<AnimatedCheckmark> createState() => _AnimatedCheckmarkState();
}

class _AnimatedCheckmarkState extends State<AnimatedCheckmark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    final reduceMotion = WidgetsBinding
        .instance
        .platformDispatcher
        .accessibilityFeatures
        .disableAnimations;
    if (reduceMotion) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? context.colorScheme.successColor;
    final trackColor = widget.trackColor ?? color.withValues(alpha: 0.16);
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _CheckmarkPainter(
              progress: _controller.value,
              color: color,
              trackColor: trackColor,
              strokeWidth: widget.strokeWidth ?? widget.size * 0.068,
            ),
          );
        },
      ),
    );
  }
}

class _CheckmarkPainter extends CustomPainter {
  _CheckmarkPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  static const double _popEnd = 0.38;
  static const double _ringStart = 0.10;
  static const double _ringEnd = 0.50;
  static const double _checkStart = 0.46;
  static const double _checkEnd = 0.74;
  static const double _settleStart = 0.74;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final center = size.center(Offset.zero);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final opacity = _local(progress, 0, 0.22);

    final popT = _eased(_local(progress, 0, _popEnd));
    final settleT = _local(progress, _settleStart, 1.0);
    final bounce =
        1.0 + 0.12 * math.exp(-settleT * 6) * math.sin(settleT * math.pi * 2.4);
    final scale = progress <= _popEnd
        ? Curves.easeOutBack.transform(popT)
        : bounce;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(scale);
    canvas.translate(-center.dx, -center.dy);

    final glowT = _local(progress, 0, 0.55);
    if (glowT > 0 && glowT < 1) {
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.5 * (1 - glowT) * opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawCircle(center, radius * (0.5 + glowT * 1.1), glowPaint);
    }

    final trackPaint = Paint()
      ..color = trackColor.withValues(alpha: trackColor.a * opacity)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, trackPaint);

    final ringT = _eased(_local(progress, _ringStart, _ringEnd));
    if (ringT > 0) {
      final ringPaint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * ringT,
        false,
        ringPaint,
      );
    }

    final checkT = _eased(_local(progress, _checkStart, _checkEnd));
    if (checkT > 0) {
      final p0 = Offset(size.width * 0.30, size.height * 0.53);
      final p1 = Offset(size.width * 0.44, size.height * 0.66);
      final p2 = Offset(size.width * 0.72, size.height * 0.35);
      final seg1 = (p1 - p0).distance;
      final seg2 = (p2 - p1).distance;
      final total = seg1 + seg2;
      final travelled = checkT * total;

      final path = Path()..moveTo(p0.dx, p0.dy);
      if (travelled <= seg1) {
        final localT = seg1 == 0 ? 0.0 : travelled / seg1;
        path.lineTo(
          p0.dx + (p1.dx - p0.dx) * localT,
          p0.dy + (p1.dy - p0.dy) * localT,
        );
      } else {
        path.lineTo(p1.dx, p1.dy);
        final localT = seg2 == 0 ? 0.0 : (travelled - seg1) / seg2;
        path.lineTo(
          p1.dx + (p2.dx - p1.dx) * localT,
          p1.dy + (p2.dy - p1.dy) * localT,
        );
      }

      final checkPaint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(path, checkPaint);
    }

    canvas.restore();
  }

  double _local(double t, double start, double end) {
    if (end <= start) return t >= end ? 1 : 0;
    return ((t - start) / (end - start)).clamp(0.0, 1.0);
  }

  double _eased(double t) => Curves.easeOut.transform(t);

  @override
  bool shouldRepaint(covariant _CheckmarkPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.strokeWidth != strokeWidth;
}
