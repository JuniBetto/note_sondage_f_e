import 'package:flutter/material.dart';
import 'color_palette.dart';

class AppTypography {
  static const String fontFamily = "Nunito";


  static TextTheme textTheme(bool isLightTheme) {
    return TextTheme(
      displayLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 57,
        height: 64 / 57,
        fontWeight: FontWeight.w400,
        color: isLightTheme ? ColorPalette.gray[7] : ColorPalette.gray[1],
      ),
      displayMedium: TextStyle(
        fontFamily: fontFamily,
        height: 52 / 45,
        fontSize: 45,
        fontWeight: FontWeight.w400,
        color: isLightTheme ? ColorPalette.gray[7] : ColorPalette.gray[1],
      ),
      displaySmall: TextStyle(
        fontFamily: fontFamily,
        height: 44 / 36,
        fontSize: 36,
        fontWeight: FontWeight.w400,
        color: isLightTheme ? ColorPalette.gray[7] : ColorPalette.gray[1],
      ),
      headlineLarge: TextStyle(
        fontFamily: fontFamily,
        height: 40 / 32,
        fontSize: 32,
        fontWeight: FontWeight.w400,
        color: isLightTheme ? ColorPalette.gray[7] : ColorPalette.gray[1],
      ),
      headlineMedium: TextStyle(
        fontFamily: fontFamily,
        height: 36 / 28,
        fontSize: 28,
        fontWeight: FontWeight.w400,
        color: isLightTheme ? ColorPalette.gray[7] : ColorPalette.gray[1],
      ),
      headlineSmall: TextStyle(
        fontFamily: fontFamily,
        height: 32 / 24,
        fontSize: 24,
        fontWeight: FontWeight.w400,
        color: isLightTheme ? ColorPalette.gray[7] : ColorPalette.gray[1],
      ),
      titleLarge: TextStyle(
        fontFamily: fontFamily,
        height: 28 / 22,
        fontSize: 22,
        fontWeight: FontWeight.w400,
        color: isLightTheme ? ColorPalette.gray[7] : ColorPalette.gray[1],
      ),
      titleMedium: TextStyle(
        fontFamily: fontFamily,
        height: 24 / 16,
        fontSize: 16,
        letterSpacing: 0.15,
        fontWeight: FontWeight.w500,
        color: isLightTheme ? ColorPalette.gray[7] : ColorPalette.gray[1],
      ),
      titleSmall: TextStyle(
        fontFamily: fontFamily,
        height: 20 / 14,
        fontSize: 14,
        letterSpacing: 0.1,
        fontWeight: FontWeight.w500,
        color: isLightTheme ? ColorPalette.gray[7] : ColorPalette.gray[1],
      ),
      labelLarge: TextStyle(
        fontFamily: fontFamily,
        height: 20 / 14,
        fontSize: 14,
        letterSpacing: 0.1,
        fontWeight: FontWeight.w500,
        color: isLightTheme ? ColorPalette.gray[7] : ColorPalette.gray[3],
      ),
      labelMedium: TextStyle(
        fontFamily: fontFamily,
        height: 16 / 12,
        fontSize: 12,
        letterSpacing: 0.5,
        fontWeight: FontWeight.w500,
        color: isLightTheme ? ColorPalette.gray[7] : ColorPalette.gray[3],
      ),
      labelSmall: TextStyle(
        fontFamily: fontFamily,
        height: 16 / 11,
        fontSize: 11,
        letterSpacing: 0.5,
        fontWeight: FontWeight.w500,
        color: isLightTheme ? ColorPalette.gray[7] : ColorPalette.gray[3],
      ),
      bodyLarge: TextStyle(
        fontFamily: fontFamily,
        height: 24 / 16,
        fontSize: 16,
        letterSpacing: 0.5,
        fontWeight: FontWeight.w400,
        color: isLightTheme ? ColorPalette.gray[5] : ColorPalette.gray[4],
      ),
      bodyMedium: TextStyle(
        fontFamily: fontFamily,
        height: 20 / 14,
        fontSize: 14,
        letterSpacing: 0.25,
        fontWeight: FontWeight.w400,
        color: isLightTheme ? ColorPalette.gray[7] : ColorPalette.gray[3],
      ),
      bodySmall: TextStyle(
        fontFamily: fontFamily,
        height: 16 / 12,
        fontSize: 12,
        letterSpacing: 0.4,
        fontWeight: FontWeight.w400,
        color: isLightTheme ? ColorPalette.gray[7] : ColorPalette.gray[3],
      ),

    );
  }
}

extension CustomStyles on TextTheme{
  TextStyle get largeText =>TextStyle(
  fontFamily: AppTypography.fontFamily,
  height: 12 / 8,
  fontSize: 8,
  letterSpacing: 0.5,
  fontWeight: FontWeight.w400,
  color: bodyLarge?.color
  );
  TextStyle get mediumText => TextStyle(
  fontFamily: AppTypography.fontFamily,
  height: 8 / 6,
  fontSize: 6,
  letterSpacing: 0.25,
  fontWeight: FontWeight.w400,
  color: bodyMedium?.color,
  );
  TextStyle get smallText =>  TextStyle(
  fontFamily: AppTypography.fontFamily,
  height: 6 / 4,
  fontSize: 4,
  letterSpacing: 0.25,
  fontWeight: FontWeight.w400,
  color: bodySmall?.color,
  );
}