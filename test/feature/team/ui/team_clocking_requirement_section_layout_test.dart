import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_sondage/feature/team/ui/widgets/team_clocking_requirement_section.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';

// Nei test il font e' Ahem (glifi quadrati, molto piu' larghi del reale): si
// verificano i comportamenti relativi, non le misure in pixel.
void main() {
  Future<AppLocalizations> pumpSection(
    WidgetTester tester,
    double width, {
    double textScale = 1,
  }) async {
    tester.view.physicalSize = Size(width, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    late AppLocalizations loc;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(width, 3000),
            textScaler: TextScaler.linear(textScale),
          ),
          child: Builder(
            builder: (context) {
              loc = AppLocalizations.of(context)!;
              return Scaffold(
                body: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: TeamClockingRequirementSection(
                      clockingRequired: true,
                      onClockingRequiredChanged: (_) {},
                      requiredStartDate: '2026-10-01',
                      onRequiredStartDateChanged: (_) {},
                      requiredEndDate: null,
                      onRequiredEndDateChanged: (_) {},
                      reminderTime: '09:00',
                      onReminderTimeChanged: (_) {},
                      missingAlertTime: '10:00',
                      onMissingAlertTimeChanged: (_) {},
                      openAlertTime: '22:00',
                      onOpenAlertTimeChanged: (_) {},
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return loc;
  }

  testWidgets('value sits beside the text when there is room', (tester) async {
    final loc = await pumpSection(tester, 2400);
    final title = tester.getRect(
      find.text(loc.teamClockingRequirementEndDateTitle),
    );
    final value = tester.getRect(
      find.text(loc.teamClockingRequirementNoEndDate),
    );
    expect(value.left, greaterThan(title.right));
    expect((value.center.dy - title.center.dy).abs(), lessThan(120));
  });

  testWidgets('narrow screen: text keeps a readable column, value goes below', (
    tester,
  ) async {
    final loc = await pumpSection(tester, 600, textScale: 1.3);
    final subtitle = tester.getRect(
      find.text(loc.teamClockingRequirementEndDateSubtitle),
    );
    final value = tester.getRect(
      find.text(loc.teamClockingRequirementNoEndDate),
    );
    expect(
      subtitle.width,
      greaterThanOrEqualTo(150),
      reason: 'the description must not collapse into a thin column',
    );
    expect(value.top, greaterThanOrEqualTo(subtitle.bottom));
    expect(tester.takeException(), isNull);
  });

  testWidgets('no "!" when the value fits entirely', (tester) async {
    await pumpSection(tester, 2400);
    expect(find.byIcon(Icons.error_outline_rounded), findsNothing);
  });

  testWidgets(
    '"!" appears only when the value is cut and shows the full text',
    (tester) async {
      final loc = await pumpSection(tester, 330);
      final icons = find.byIcon(Icons.error_outline_rounded);
      expect(icons, findsWidgets);

      // The "!" belonging to the end-date tile: its value is cut with "...".
      final endTile = find.ancestor(
        of: find.text(loc.teamClockingRequirementEndDateTitle),
        matching: find.byType(InkWell),
      );
      final endIcon = find.descendant(of: endTile.first, matching: icons);
      expect(endIcon, findsOneWidget);

      await tester.ensureVisible(endIcon);
      await tester.pumpAndSettle();
      await tester.tap(endIcon);
      await tester.pumpAndSettle();

      // Tapping "!" opens the full message, not the date picker.
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.byType(DatePickerDialog), findsNothing);
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text(loc.teamClockingRequirementNoEndDate),
        ),
        findsOneWidget,
      );
      await tester.tap(find.text(loc.close));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    },
  );
}
