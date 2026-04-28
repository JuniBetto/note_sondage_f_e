import 'package:flutter/material.dart';
import 'package:note_sondage/infrastructure/model/theme_entitie.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'text_theme.dart';

export 'extensions/theme_extensions.dart';
export 'color_palette.dart';
export 'text_theme.dart';

/// Main theme configuration class
class AppTheme {
  static ThemeData getThemeMode(ThemeModeType mode) {
    switch (mode) {
      case ThemeModeType.light:
        return buildTheme(false);
      case ThemeModeType.dark:
        return buildTheme(true);
      case ThemeModeType.system:
        return ThemeData.fallback();
    }
  }

  static ThemeData buildTheme(bool isDark) {
    final colorScheme = ThemeData(
      brightness: isDark ? Brightness.dark : Brightness.light,
    ).colorScheme;
    const kDefaultPadding = EdgeInsets.symmetric(horizontal: 12);
    const kBorderRadius = 8.0;

    final kRoundedShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(kBorderRadius)),
    );
    return ThemeData(
      colorScheme: ColorScheme(
        primary: colorScheme.bgColor!,
        secondary: Colors.blue, //colorScheme.bgsecondary!,
        surface: colorScheme.bgsurface!,
        surfaceContainer: colorScheme.error,
        error: colorScheme.error,
        onPrimary: colorScheme.onPrimary,
        onSecondary: colorScheme.onSecondary,
        onSurface: colorScheme.textColor!,
        onError: Colors.transparent,

        brightness: isDark ? Brightness.dark : Brightness.light,
      ),
      scaffoldBackgroundColor: colorScheme.bgsurface!,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.bgNavbarSurface,
        elevation: 2,
        titleTextStyle: AppTypography.textTheme(isDark).displayLarge,
        leadingWidth: 100,
        shape: Border(
          bottom: BorderSide(color: colorScheme.bgborderLogin!, width: 3),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: kDefaultPadding,
          shape: kRoundedShape,
          backgroundColor: colorScheme.secondary,
          foregroundColor: colorScheme.surface,
          textStyle: AppTypography.textTheme(isDark).labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.textColor,
          backgroundColor: colorScheme.bgsecondary,
          //textStyle: AppTypography.textTheme(isDark).labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: kDefaultPadding,
          shape: kRoundedShape,
          side: BorderSide(color: colorScheme.primary, width: 1.5),
          foregroundColor: colorScheme.textColor,
          textStyle: AppTypography.textTheme(isDark).labelLarge,
        ),
      ),
      fontFamily: AppTypography.fontFamily,
      textTheme: AppTypography.textTheme(!isDark),
    );
  }
}
