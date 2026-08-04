import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';

class TeamManagementLoadingSpinner extends StatefulWidget {
  const TeamManagementLoadingSpinner({
    super.key,
    this.size = 220,
    this.message,
  });

  final double size;
  final String? message;

  @override
  State<TeamManagementLoadingSpinner> createState() =>
      _TeamManagementLoadingSpinnerState();
}

class _TeamManagementLoadingSpinnerState
    extends State<TeamManagementLoadingSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primary = colorScheme.primaryColor ?? colorScheme.primary;
    final accent = colorScheme.bgsecondary ?? primary;
    final glow = accent.withValues(alpha: 0.28);
    final subtleGlow = primary.withValues(alpha: 0.14);
    final textColor = colorScheme.textColor ?? colorScheme.onSurface;
    final helperColor = colorScheme.descriptionColor ?? colorScheme.onSurface;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          final pulse = 0.92 + (math.sin(t * math.pi * 2) * 0.08);
          final drift = math.sin(t * math.pi * 2) * 0.022;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LoadingBars(
                progress: t,
                color: accent,
                subtleColor: primary.withValues(alpha: 0.35),
                width: widget.size * 0.58,
              ),
              SizedBox(height: widget.size * 0.1),
              SizedBox(
                width: widget.size,
                height: widget.size * 0.78,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: widget.size * 0.72,
                      height: widget.size * 0.72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: glow,
                            blurRadius: widget.size * 0.24,
                            spreadRadius: widget.size * 0.025,
                          ),
                          BoxShadow(
                            color: subtleGlow,
                            blurRadius: widget.size * 0.14,
                            spreadRadius: widget.size * 0.01,
                          ),
                        ],
                      ),
                    ),
                    Opacity(
                      opacity: 0.22 + (math.sin(t * math.pi * 2) + 1) * 0.06,
                      child: Transform.scale(
                        scale: 1.02 + (1 - pulse) * 0.16,
                        child: _LogoMark(
                          size: widget.size,
                          color: accent.withValues(alpha: 0.48),
                        ),
                      ),
                    ),
                    Transform.translate(
                      offset: Offset(0, widget.size * 0.01 * math.sin(t * 2)),
                      child: Transform.rotate(
                        angle: drift,
                        child: Transform.scale(
                          scale: pulse,
                          child: _LogoMark(size: widget.size, color: textColor),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: widget.size * 0.05),
              _MorphingWord(
                text: 'TEAM',
                progress: t,
                color: textColor,
                fontSize: widget.size * 0.18,
                letterGap: widget.size * 0.022,
                amplitude: widget.size * 0.028,
                shadowColor: glow,
                weight: FontWeight.w900,
              ),
              SizedBox(height: widget.size * 0.035),
              _MorphingSubtitle(
                text: 'MANAGEMENT',
                progress: t,
                color: accent,
                lineColor: accent.withValues(alpha: 0.75),
                fontSize: widget.size * 0.07,
                width: widget.size * 0.78,
                shadowColor: subtleGlow,
              ),
              if (widget.message case final message?) ...[
                SizedBox(height: widget.size * 0.08),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: helperColor,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _LogoMark extends StatelessWidget {
  const _LogoMark({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Align(
        alignment: Alignment.topCenter,
        heightFactor: 0.76,
        child: SizedBox.square(
          dimension: size,
          child: ColorFiltered(
            colorFilter: ColorFilter.mode(color, BlendMode.modulate),
            child: Image.asset(
              'assets/images/logo.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.business_center_rounded,
                  size: size * 0.42,
                  color: color,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingBars extends StatelessWidget {
  const _LoadingBars({
    required this.progress,
    required this.color,
    required this.subtleColor,
    required this.width,
  });

  final double progress;
  final Color color;
  final Color subtleColor;
  final double width;

  @override
  Widget build(BuildContext context) {
    final barWidths = <double>[0.22, 0.18, 0.16, 0.13];

    return SizedBox(
      width: width,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(barWidths.length, (index) {
          final localPhase = progress * math.pi * 2 - (index * 0.45);
          final active = ((math.sin(localPhase) + 1) / 2).clamp(0.0, 1.0);
          final fill = Color.lerp(subtleColor, color, active)!;

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: width * 0.014),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: width * (barWidths[index] + active * 0.02),
              height: 5 + (active * 1.5),
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: fill.withValues(alpha: 0.35),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _MorphingWord extends StatelessWidget {
  const _MorphingWord({
    required this.text,
    required this.progress,
    required this.color,
    required this.fontSize,
    required this.letterGap,
    required this.amplitude,
    required this.shadowColor,
    required this.weight,
  });

  final String text;
  final double progress;
  final Color color;
  final double fontSize;
  final double letterGap;
  final double amplitude;
  final Color shadowColor;
  final FontWeight weight;

  @override
  Widget build(BuildContext context) {
    final letters = text.split('');

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < letters.length; index++) ...[
          _MorphingGlyph(
            glyph: letters[index],
            index: index,
            progress: progress,
            color: color,
            fontSize: fontSize,
            amplitude: amplitude,
            shadowColor: shadowColor,
            weight: weight,
          ),
          if (index < letters.length - 1) SizedBox(width: letterGap),
        ],
      ],
    );
  }
}

class _MorphingSubtitle extends StatelessWidget {
  const _MorphingSubtitle({
    required this.text,
    required this.progress,
    required this.color,
    required this.lineColor,
    required this.fontSize,
    required this.width,
    required this.shadowColor,
  });

  final String text;
  final double progress;
  final Color color;
  final Color lineColor;
  final double fontSize;
  final double width;
  final Color shadowColor;

  @override
  Widget build(BuildContext context) {
    final linePulse =
        0.75 + (((math.sin(progress * math.pi * 2) + 1) / 2) * 0.25);
    final letters = text.split('');

    return SizedBox(
      width: width,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _AccentLine(color: lineColor, width: width * 0.16 * linePulse),
          SizedBox(width: width * 0.035),
          Flexible(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var index = 0; index < letters.length; index++)
                  Transform.translate(
                    offset: Offset(
                      0,
                      math.sin(progress * math.pi * 2 + (index * 0.35)) * 2.2,
                    ),
                    child: Text(
                      letters[index],
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: fontSize,
                        height: 1,
                        letterSpacing: fontSize * 0.18,
                        fontWeight: FontWeight.w700,
                        color: Color.lerp(
                          color.withValues(alpha: 0.7),
                          color,
                          ((math.sin(progress * math.pi * 2 + index) + 1) / 2),
                        ),
                        shadows: [
                          Shadow(
                            color: shadowColor.withValues(alpha: 0.55),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: width * 0.035),
          _AccentLine(color: lineColor, width: width * 0.16 * linePulse),
        ],
      ),
    );
  }
}

class _AccentLine extends StatelessWidget {
  const _AccentLine({required this.color, required this.width});

  final Color color;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 2.5,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}

class _MorphingGlyph extends StatelessWidget {
  const _MorphingGlyph({
    required this.glyph,
    required this.index,
    required this.progress,
    required this.color,
    required this.fontSize,
    required this.amplitude,
    required this.shadowColor,
    required this.weight,
  });

  final String glyph;
  final int index;
  final double progress;
  final Color color;
  final double fontSize;
  final double amplitude;
  final Color shadowColor;
  final FontWeight weight;

  @override
  Widget build(BuildContext context) {
    final phase = (progress * math.pi * 2 * 1.2) + (index * 0.75);
    final vertical = math.sin(phase) * amplitude;
    final scaleX = 1 + (math.sin(phase + 0.8) * 0.14);
    final scaleY = 1 - (math.sin(phase) * 0.12);
    final glowStrength = ((math.sin(phase - 0.4) + 1) / 2);
    final opacity = 0.82 + (glowStrength * 0.18);

    return Opacity(
      opacity: opacity,
      child: Transform.translate(
        offset: Offset(0, vertical),
        child: Transform.scale(
          alignment: Alignment.bottomCenter,
          scaleX: scaleX,
          scaleY: scaleY,
          child: Text(
            glyph,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: fontSize,
              height: 1,
              fontWeight: weight,
              color: color,
              shadows: [
                Shadow(
                  color: shadowColor.withValues(
                    alpha: 0.32 + glowStrength * 0.28,
                  ),
                  blurRadius: 12 + (glowStrength * 8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
