import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/ui/mobile/widgets/login/login_mobile.dart';
import 'package:note_sondage/ui/mobile/widgets/login/tab_bar_component.dart';
import 'package:note_sondage/ui/widgets/custom_app_button.dart';
import 'package:note_sondage/ui/widgets/custom_input_field.dart';
import 'package:note_sondage/ui/widgets/sso_login.dart';

void main() {
  final loginPage = MediaQuery(
    data: MediaQueryData(),
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: LoginMobile(),
    ),
  );

  final buttonOnLogin = find.byType(CustomAppButton);
  final tabBar = find.byType(TabBarComponent);
  final text = find.byType(Text);
  final textfield = find.byType(CustomInputField);
  final ssoLogin = find.byType(SsoLogin);

  testWidgets('Login page section login is present', (
    WidgetTester tester,
  ) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    await tester.pumpWidget(loginPage);
    expect(tabBar, findsOneWidget);

    final loginOnTab = find.byKey(const Key('login_tab'));
    await tester.tap(loginOnTab);
    await tester.pump();
    final loginTitle = find.text(l10n.login);
    // await tester.pumpAndSettle();

    expect(text, findsNWidgets(10));
    expect(loginTitle, findsNWidgets(2));
    expect(textfield, findsNWidgets(2));
    expect(buttonOnLogin, findsNWidgets(2));
    expect(ssoLogin, findsOneWidget);

    //expect(buttonOnLogin, findsNWidgets(2));

    //expect(find.byType(ElevatedButton), findsOneWidget);
  });

  testWidgets('Login page section register is present', (
    WidgetTester tester,
  ) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    await tester.pumpWidget(loginPage);
    //await tester.tap(tabBar);

    await tester.tap(find.byKey(const Key('register_tab')));
    await tester.pumpAndSettle();
    final registerTitle = find.text(l10n.register);

    expect(registerTitle, findsNWidgets(2));
    expect(textfield, findsNWidgets(4));

    expect(buttonOnLogin, findsOneWidget);

    expect(ssoLogin, findsOneWidget);
  });
}
