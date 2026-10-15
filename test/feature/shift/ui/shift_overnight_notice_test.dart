import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_sondage/feature/shift/ui/widgets/shift_overnight_notice.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';

TimeOfDay _t(int h, [int m = 0]) => TimeOfDay(hour: h, minute: m);

void main() {
  Future<void> pump(
    WidgetTester tester, {
    required TimeOfDay start,
    required TimeOfDay end,
    required bool overnight,
    String locale = 'it',
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: Locale(locale),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ShiftOvernightNotice(
            start: start,
            end: end,
            overnight: overnight,
          ),
        ),
      ),
    );
  }

  testWidgets('hidden for a same-day shift', (tester) async {
    await pump(tester, start: _t(9), end: _t(18), overnight: false);
    expect(find.byType(Text), findsNothing);
  });

  testWidgets('00:00-00:00 says 24 hours and a single day', (tester) async {
    await pump(tester, start: _t(0), end: _t(0), overnight: true);
    expect(
      find.text(
        'Questo turno dura 24h 0m e finisce a mezzanotte: occupa un solo giorno.',
      ),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.info_outline), findsOneWidget);
  });

  testWidgets('06:00-07:00 next day warns about more than 24 hours', (
    tester,
  ) async {
    await pump(tester, start: _t(6), end: _t(7), overnight: true);
    expect(
      find.text(
        'Questo turno dura più di 24 ore (25h 0m) e occupa due giorni.',
      ),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
  });

  testWidgets('a night shift states it ends the next day and covers two days', (
    tester,
  ) async {
    await pump(
      tester,
      start: _t(22),
      end: _t(6),
      overnight: true,
      locale: 'fr',
    );
    expect(
      find.text(
        'Ce quart se termine le lendemain et dure 8h 0m : il occupe deux jours.',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'end before start without the flag still tells it ends next day',
    (tester) async {
      await pump(tester, start: _t(22), end: _t(6), overnight: false);
      expect(find.textContaining('finisce il giorno dopo'), findsOneWidget);
    },
  );
}
