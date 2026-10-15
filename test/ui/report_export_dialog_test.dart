import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_sondage/core/export/report_table_data.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/ui/widgets/report_export_dialog.dart';

enum _Col { date, user, account, duration, note }

const _defaults = [_Col.date, _Col.user, _Col.note];

void main() {
  void useTallScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  /// Opens the dialog and exposes the result of the user's choice.
  Future<ReportExportSelection<_Col>? Function()> openDialog(
    WidgetTester tester, {
    String locale = 'en',
    List<_Col> initial = _defaults,
  }) async {
    useTallScreen(tester);
    ReportExportSelection<_Col>? result;
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
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await ReportExportDialog.show<_Col>(
                context,
                subtitle: 'Team · 01/10/2026 - 31/10/2026 · 4',
                allColumns: _Col.values,
                labelOf: (column) => column.name,
                initialColumns: initial,
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return () => result;
  }

  testWidgets('lists every column and counts the selected ones', (
    tester,
  ) async {
    await openDialog(tester, locale: 'fr');
    expect(find.byType(Checkbox), findsNWidgets(5));
    expect(find.text('3 sur 5'), findsOneWidget);
    expect(find.text('PDF'), findsOneWidget);
    expect(find.text('Télécharger'), findsOneWidget);
  });

  testWidgets('unchecking a column removes it from the result', (tester) async {
    final result = await openDialog(tester, locale: 'it');

    await tester.tap(find.text('note'));
    await tester.pumpAndSettle();
    expect(find.text('2 di 5'), findsOneWidget);

    await tester.tap(find.text('Scarica'));
    await tester.pumpAndSettle();
    expect(result()!.format, ReportExportFormat.pdf);
    expect(result()!.columns, [_Col.date, _Col.user]);
  });

  testWidgets('optional columns are off by default and can be enabled', (
    tester,
  ) async {
    final result = await openDialog(tester);
    expect(find.text('3 of 5'), findsOneWidget);

    await tester.ensureVisible(find.text('account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('account'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('duration'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('duration'));
    await tester.pumpAndSettle();
    expect(find.text('5 of 5'), findsOneWidget);

    await tester.tap(find.text('Download'));
    await tester.pumpAndSettle();
    expect(result()!.columns, containsAll([_Col.account, _Col.duration]));
  });

  testWidgets('lets the user pick CSV and Excel formats', (tester) async {
    final result = await openDialog(tester);

    expect(find.text('PDF'), findsOneWidget);
    expect(find.text('CSV'), findsOneWidget);
    expect(find.text('Excel'), findsOneWidget);

    await tester.tap(find.text('Excel'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Download'));
    await tester.pumpAndSettle();
    expect(result()!.format, ReportExportFormat.excel);
  });

  testWidgets('keeps at least one column selected', (tester) async {
    await openDialog(tester, locale: 'fr', initial: const [_Col.date]);
    await tester.tap(find.text('date'));
    await tester.pumpAndSettle();
    expect(find.text('1 sur 5'), findsOneWidget);
  });
}
