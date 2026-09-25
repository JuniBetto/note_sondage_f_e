import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:note_sondage/core/config/routes.dart';
import 'package:note_sondage/feature/sondage/ui/mobile/widgets/sondage_mobile.dart';
import 'package:note_sondage/ui/bloc/navigation_bloc/navigation_bloc.dart';
import 'package:note_sondage/ui/mobile/navigation/mobile_shell_navigation.dart';

void main() {
  setUp(() => SondageMobile.requestedInitialTab = 0);

  Future<NavigationBloc> pumpStandaloneRoute(
    WidgetTester tester, {
    required int tab,
  }) async {
    final bloc = NavigationBloc();
    addTearDown(bloc.close);
    final router = GoRouter(
      initialLocation: '/standalone',
      routes: [
        GoRoute(
          path: '/standalone',
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () => openSondageInMobileShell(context, tab: tab),
              child: const Text('back'),
            ),
          ),
        ),
        GoRoute(
          path: RouterPaths.home,
          builder: (_, _) => const Scaffold(body: Text('shell')),
        ),
        GoRoute(
          path: RouterPaths.sondageChat,
          builder: (_, _) => const Text('bare-sondage'),
        ),
      ],
    );
    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.tap(find.text('back'));
    await tester.pumpAndSettle();
    return bloc;
  }

  testWidgets('returns to the chat tab through the shell, not the bare page', (
    tester,
  ) async {
    final bloc = await pumpStandaloneRoute(tester, tab: 2);

    expect(find.text('shell'), findsOneWidget);
    expect(find.text('bare-sondage'), findsNothing);
    expect(bloc.state, mobileShellSondageNavIndex);
    expect(SondageMobile.requestedInitialTab, 2);
  });

  testWidgets('list tab does not leave a stale requested tab', (tester) async {
    SondageMobile.requestedInitialTab = 0;
    final bloc = await pumpStandaloneRoute(tester, tab: 0);

    expect(find.text('shell'), findsOneWidget);
    expect(bloc.state, mobileShellSondageNavIndex);
    expect(SondageMobile.requestedInitialTab, 0);
  });
}
