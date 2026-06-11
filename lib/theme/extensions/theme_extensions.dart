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



@immutable
class CustomTextTheme extends ThemeExtension<CustomTextTheme> {
  const CustomTextTheme(  {
    required this.largeText,required this.mediumText,required this.smallText,

  });

  final TextStyle largeText;
  final TextStyle mediumText;
  final TextStyle smallText;

  @override
  CustomTextTheme copyWith({TextStyle? largeText,TextStyle? mediumText, TextStyle? smallText}) {
    return CustomTextTheme(
      largeText: largeText ?? this.largeText,
      mediumText: mediumText ?? this.mediumText,
      smallText: smallText ?? this.smallText,
    );
  }

  @override
  CustomTextTheme lerp(ThemeExtension<CustomTextTheme>? other, double t) {
    if (other is! CustomTextTheme) return this;
    return CustomTextTheme(
      largeText: TextStyle.lerp(largeText, other.largeText, t)!,
      mediumText: TextStyle.lerp(mediumText, other.mediumText, t)!,
      smallText: TextStyle.lerp(smallText, other.smallText, t)!,
    );
  }
}
