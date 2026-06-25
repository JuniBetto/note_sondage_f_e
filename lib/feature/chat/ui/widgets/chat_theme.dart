import 'package:flutter/material.dart';
import 'package:note_sondage/core/utils/extention_color.dart';

class ChatThemeTokens {
  const ChatThemeTokens._();

  static const Color chatCanvasColor = Color(0xFFFFFDF8);
  static const Color incomingBubbleColor = Color(0xFFD9FF88);
  static const Color outgoingBubbleColor = Color(0xFF1C5B4F);

  static Color resolveTeamAccentColor(String? rawColor, Color fallback) {
    if (rawColor == null || rawColor.trim().isEmpty) {
      return fallback;
    }
    try {
      return rawColor.toColor();
    } catch (_) {
      return fallback;
    }
  }

  static ChatComposerPalette composerPalette(Color accentColor) {
    final hsl = HSLColor.fromColor(accentColor);
    final borderColor = hsl
        .withLightness((hsl.lightness + 0.14).clamp(0.66, 0.82))
        .withSaturation((hsl.saturation * 0.55).clamp(0.14, 0.62))
        .toColor();
    final inputSurface = hsl
        .withLightness(0.97)
        .withSaturation((hsl.saturation * 0.14).clamp(0.02, 0.18))
        .toColor();
    final subtleFill = hsl
        .withLightness((hsl.lightness + 0.30).clamp(0.88, 0.96))
        .withSaturation((hsl.saturation * 0.35).clamp(0.08, 0.40))
        .toColor();
    final iconTint = hsl
        .withLightness((hsl.lightness - 0.08).clamp(0.22, 0.46))
        .withSaturation((hsl.saturation * 0.92).clamp(0.18, 0.82))
        .toColor();
    final onAccent =
        ThemeData.estimateBrightnessForColor(accentColor) == Brightness.dark
        ? Colors.white
        : const Color(0xFF14210F);

    return ChatComposerPalette(
      accentColor: accentColor,
      onAccentColor: onAccent,
      surfaceColor: Colors.white,
      borderColor: borderColor,
      inputSurfaceColor: inputSurface,
      subtleFillColor: subtleFill,
      iconTintColor: iconTint,
    );
  }
}

class ChatComposerPalette {
  const ChatComposerPalette({
    required this.accentColor,
    required this.onAccentColor,
    required this.surfaceColor,
    required this.borderColor,
    required this.inputSurfaceColor,
    required this.subtleFillColor,
    required this.iconTintColor,
  });

  final Color accentColor;
  final Color onAccentColor;
  final Color surfaceColor;
  final Color borderColor;
  final Color inputSurfaceColor;
  final Color subtleFillColor;
  final Color iconTintColor;
}
