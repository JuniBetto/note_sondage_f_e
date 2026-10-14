import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_sondage/feature/shift/ui/utils/shift_report_table_data.dart';
import 'package:note_sondage/feature/shift/ui/widgets/shift_report_export_dialog.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';

void main() {
  void useTallScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Future<void> openDialog(
    WidgetTester tester, {
    List<ShiftReportColumn>? initial,
  }) async {
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
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              await ShiftReportExportDialog.show(
                context,
                subtitle: 'Team · 01/10/2026 - 31/10/2026 · 4',
                initialColumns: initial ?? ShiftReportColumn.defaultExport,
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('PDF'), findsOneWidget);
    expect(find.text('Télécharger'), findsOneWidget);
  }

  testWidgets('returns every column by default', (tester) async {
    useTallScreen(tester);
    await openDialog(tester);
    expect(find.byType(Checkbox), findsNWidgets(8));
    expect(find.text('7 sur 8'), findsOneWidget);
  });

  testWidgets('unchecking a column removes it from the result', (tester) async {
    useTallScreen(tester);
    ShiftReportExportSelection? result;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('it'),
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
              result = await ShiftReportExportDialog.show(
                context,
                subtitle: 'x',
                initialColumns: ShiftReportColumn.defaultExport,
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nota'));
    await tester.pumpAndSettle();
    expect(find.text('6 di 8'), findsOneWidget);

    await tester.tap(find.text('Scarica'));
    await tester.pumpAndSettle();
    expect(result, isNotNull);
    expect(result!.format, ShiftReportExportFormat.pdf);
    expect(result!.columns, isNot(contains(ShiftReportColumn.note)));
    expect(result!.columns.length, 6);
    expect(result!.columns, isNot(contains(ShiftReportColumn.account)));
  });

  testWidgets('lets the user pick CSV and Excel formats', (tester) async {
    useTallScreen(tester);
    ShiftReportExportSelection? result;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
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
              result = await ShiftReportExportDialog.show(
                context,
                subtitle: 'x',
                initialColumns: ShiftReportColumn.defaultExport,
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('PDF'), findsOneWidget);
    expect(find.text('CSV'), findsOneWidget);
    expect(find.text('Excel'), findsOneWidget);

    await tester.tap(find.text('Excel'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Download'));
    await tester.pumpAndSettle();
    expect(result!.format, ShiftReportExportFormat.excel);
  });

  testWidgets('account column is off by default and can be enabled', (
    tester,
  ) async {
    useTallScreen(tester);
    ShiftReportExportSelection? result;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
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
              result = await ShiftReportExportDialog.show(
                context,
                subtitle: 'x',
                initialColumns: ShiftReportColumn.defaultExport,
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Account'), findsOneWidget);
    expect(find.text('7 of 8'), findsOneWidget);

    await tester.ensureVisible(find.text('Account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();
    expect(find.text('8 of 8'), findsOneWidget);

    await tester.tap(find.text('Download'));
    await tester.pumpAndSettle();
    expect(result!.columns, contains(ShiftReportColumn.account));
  });

  testWidgets('keeps at least one column selected', (tester) async {
    useTallScreen(tester);
    await openDialog(tester, initial: const [ShiftReportColumn.date]);
    final dateTile = find.text('Date');
    await tester.tap(dateTile);
    await tester.pumpAndSettle();
    expect(find.text('1 sur 8'), findsOneWidget);
  });
}
