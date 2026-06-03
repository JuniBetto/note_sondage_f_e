import 'package:flutter/material.dart';
import 'color_scheme/color_scheme.dart';

export 'color_scheme/color_scheme.dart';

extension ThemeExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  // ── Typography shortcuts ──
  TextStyle? get displayLarge => Theme.of(this).textTheme.displayLarge;
  TextStyle? get titleLarge => Theme.of(this).textTheme.titleLarge;
  TextStyle? get titleMedium => Theme.of(this).textTheme.titleMedium;
  TextStyle? get titleSmall => Theme.of(this).textTheme.titleSmall;
  TextStyle? get bodyLarge => Theme.of(this).textTheme.bodyLarge;
  TextStyle? get bodyMedium => Theme.of(this).textTheme.bodyMedium;
  TextStyle? get bodySmall => Theme.of(this).textTheme.bodySmall;
  TextStyle? get labelLarge => Theme.of(this).textTheme.labelLarge;
  TextStyle? get labelSmall => Theme.of(this).textTheme.labelSmall;

  // ── Sondage status color shortcut ──
  Color sondageStatusColor(String status) =>
      Theme.of(this).colorScheme.sondageStatusColor(status);
}
