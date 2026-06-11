import 'package:flutter/material.dart';
import '../../color_palette.dart';

extension AppColorScheme on ColorScheme {
  Color? get textColor => brightness == Brightness.light
      ? ColorPalette.gray[7]
      : ColorPalette.gray[1];

  /* Color? get bgLogin => brightness == Brightness.light
      ? ColorPalette.primary[6]
      : ColorPalette.gray[8];*/
  Color? get bgSurface => brightness == Brightness.light
      ? ColorPalette.surface
      : ColorPalette.gray[5];

  Color? get bgColor => brightness == Brightness.light
      ? ColorPalette.gray[2]
      : ColorPalette.gray[6];

  Color? get homePrimary => brightness == Brightness.light
      ? ColorPalette.gray[1]
      : ColorPalette.gray[6];

  Color? get homeSecondary => brightness == Brightness.light
      ? ColorPalette.gray[1]
      : ColorPalette.gray[5];

  Color? get homeTertiary => brightness == Brightness.light
      ? ColorPalette.gray[2]
      : ColorPalette.gray[5];

  Color? get bgDialogSecondary => brightness == Brightness.light
      ? ColorPalette.gray[1]
      : ColorPalette.gray[6];

  Color? get dialogBackgroundColor => brightness == Brightness.light
      ? ColorPalette.gray[2]
      : ColorPalette.gray[5];

  Color? get bgborderLogin => brightness == Brightness.light
      ? ColorPalette.gray[3]
      : ColorPalette.surface;

  Color? get toggleswitch => brightness == Brightness.light
      ? ColorPalette.gray[2]
      : ColorPalette.secondary[6];

  Color? get textInvertedColor => brightness == Brightness.light
      ? ColorPalette.gray[1]
      : ColorPalette.gray[7];

  Color? get bgColorNew => brightness == Brightness.light
      ? ColorPalette.surface
      : ColorPalette.scuro[1];

  Color? get bgsecondary => brightness == Brightness.light
      ? ColorPalette.primary[7]
      : ColorPalette.primary[2];

  Color? get bgtertiary => brightness == Brightness.light
      ? ColorPalette.primary[2]
      : ColorPalette.gray[7];

  //navbar
  Color? get bgNavbarSurface => brightness == Brightness.light
      ? ColorPalette.gray[1]
      : ColorPalette.gray[6];

  Color? get bgNavbarbutton => brightness == Brightness.light
      ? ColorPalette.primary[7]
      : ColorPalette.primary[4];

  Color? get bgNavbartextactive => brightness == Brightness.light
      ? ColorPalette.surface
      : ColorPalette.textPrimary;

  Color? get descriptionColor => brightness == Brightness.light
      ? ColorPalette.gray[5]
      : ColorPalette.gray[4];

  Color? get borderColor => brightness == Brightness.light
      ? ColorPalette.gray[3]
      : ColorPalette.gray[5];

  Color? get deletedBorderColor => brightness == Brightness.light
      ? ColorPalette.gray[3]
      : Colors.transparent;

  Color? get altText => ColorPalette.gray[4];

  Color? get avatarBg => brightness == Brightness.light
      ? ColorPalette.gray[4]
      : ColorPalette.gray[5];

  Color? get bottomOutline => brightness == Brightness.light
      ? ColorPalette.gray[4]
      : ColorPalette.gray[3];
  /////// nuovo calendar
  Color? get calendarBg => brightness == Brightness.light
      ? ColorPalette.secondary[1]
      : ColorPalette.secondary[9];
  Color? get calendarTextWeekBg => brightness == Brightness.light
      ? ColorPalette.gray[5]
      : ColorPalette.gray[3];
  Color? get calendarTextBg => brightness == Brightness.light
      ? ColorPalette.gray[8]
      : ColorPalette.gray[0];
  /////
  Color? get avatarTextColor => brightness == Brightness.light
      ? ColorPalette.gray[1]
      : ColorPalette.gray[3];

  Color? get buttonIsDisableBg => brightness == Brightness.light
      ? ColorPalette.gray[4]
      : ColorPalette.gray[2];

  Color? get cursorColor => brightness == Brightness.light
      ? ColorPalette.primary[4]
      : ColorPalette.primary[3];

  Color? get selectionColor => brightness == Brightness.light
      ? ColorPalette.primary[2]
      : ColorPalette.primary[4];

  Color? get primaryColor => brightness == Brightness.light
      ? ColorPalette.primary[5]
      : ColorPalette.primary[4];

  Color? get invertedPrimaryColor => brightness == Brightness.light
      ? ColorPalette.primary[4]
      : ColorPalette.primary[5];

  Color? get lightButtons => ColorPalette.primary[6];

  Color? get appBarBgColor => brightness == Brightness.light
      ? ColorPalette.primary[1]
      : ColorPalette.gray[7];

  Color? get lightgrayDarkgray => brightness == Brightness.light
      ? ColorPalette.primary[1]
      : ColorPalette.gray[7];

  Color? get textfieldFillColor => brightness == Brightness.light
      ? ColorPalette.gray[1]
      : ColorPalette.gray[6];

  Color? get textfieldInputColor => brightness == Brightness.light
      ? ColorPalette.gray[5]
      : ColorPalette.gray[1];

  Color? get menuMessageBgColor => brightness == Brightness.light
      ? ColorPalette.gray[5]
      : ColorPalette.gray[7];

  Color? get colorItemColor => brightness == Brightness.light
      ? ColorPalette.gray[1]
      : ColorPalette.gray[6];

  Color? get messageBgColor => brightness == Brightness.light
      ? ColorPalette.gray[2]
      : ColorPalette.gray[6];

  Color? get bgIcons => brightness == Brightness.light
      ? ColorPalette.gray[2]
      : ColorPalette.gray[5];

  Color? get iconLabel => brightness == Brightness.light
      ? ColorPalette.gray[5]
      : ColorPalette.gray[3];

  Color? get tableHeaderUserTeam => brightness == Brightness.light
      ? ColorPalette.gray[8]
      : ColorPalette.gray[2];

  Color? get tableBodyUserTeam => brightness == Brightness.light
      ? ColorPalette.gray[5]
      : ColorPalette.gray[3];

  Color? get timerColor => brightness == Brightness.light
      ? ColorPalette.gray[7]
      : ColorPalette.primary[2];

  Color? get selectItem => brightness == Brightness.light
      ? ColorPalette.primary[6]
      : ColorPalette.primary[4];

  Color? get deleteCard => brightness == Brightness.light
      ? ColorPalette.error.withValues(alpha: 0.6)
      : ColorPalette.error.withValues(alpha: 0.9);

  // ── Sondage status ──
  Color get sondageStatusActive => ColorPalette.statusActive;
  Color get sondageStatusDraft => ColorPalette.statusDraft;
  Color get sondageStatusClosed => ColorPalette.statusClosed;
  Color get sondageStatusCompleted => ColorPalette.statusCompleted;
  Color get sondageStatusPublished => ColorPalette.statusPublished;

  Color sondageStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return sondageStatusActive;
      case 'draft':
        return sondageStatusDraft;
      case 'closed':
        return sondageStatusClosed;
      case 'completed':
        return sondageStatusCompleted;
      case 'published':
        return sondageStatusPublished;
      default:
        return ColorPalette.gray[4];
    }
  }

  // ── Semantic shortcuts ──
  Color get successColor => ColorPalette.success;
  Color get warningColor => ColorPalette.warning;
  Color get errorColor => ColorPalette.error;
  Color get infoColor => ColorPalette.info;

  // ── Vote progress ──
  Color? get voteBarBackground => brightness == Brightness.light
      ? ColorPalette.gray[2]
      : ColorPalette.gray[6];
}
