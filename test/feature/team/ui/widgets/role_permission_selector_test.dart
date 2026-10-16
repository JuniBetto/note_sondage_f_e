import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_sondage/feature/team/ui/widgets/role_permission_selector.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';

void main() {
  Future<List<String>> pumpAndToggle(
    WidgetTester tester, {
    required List<String> selected,
    required String toggle,
  }) async {
    List<String>? result;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('it'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          body: SingleChildScrollView(
            child: RolePermissionSelector(
              selected: selected,
              onChanged: (value) => result = value,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(Key('role_permission_$toggle')));
    await tester.pump();
    return result!;
  }

  testWidgets('shows every permission with its description', (tester) async {
    await pumpAndToggle(tester, selected: const [], toggle: 'Read');

    for (final permission in ['Read', 'Update', 'Admin', 'Delete', 'Manage']) {
      expect(find.text(permission), findsOneWidget);
    }
    expect(
      find.text(
        'Modifica nome e descrizione del team e il testo dei sondaggi.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('checking adds the permission keeping the canonical order', (
    tester,
  ) async {
    final result = await pumpAndToggle(
      tester,
      selected: const ['Manage'],
      toggle: 'Update',
    );
    expect(result, ['Update', 'Manage']);
  });

  testWidgets('unchecking removes the permission', (tester) async {
    final result = await pumpAndToggle(
      tester,
      selected: const ['Read', 'Admin'],
      toggle: 'Admin',
    );
    expect(result, ['Read']);
  });
}
