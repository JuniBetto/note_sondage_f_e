import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:note_sondage/core/config/routes.dart';
import 'package:note_sondage/feature/sondage/ui/mobile/widgets/sondage_mobile.dart';
import 'package:note_sondage/feature/team/ui/mobile/teams_mobile.dart';
import 'package:note_sondage/ui/bloc/navigation_bloc/navigation_bloc.dart';
import 'package:note_sondage/ui/mobile/navigation/mobile_shell_navigation.dart';

void main() {
  setUp(() {
    SondageMobile.requestedInitialTab = 0;
    TeamsMobile.requestedInitialTab = 0;
  });

  Future<NavigationBloc> pumpStandaloneRoute(
    WidgetTester tester, {
    required void Function(BuildContext context) onBack,
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
              onPressed: () => onBack(context),
              child: const Text('back'),
            ),
          ),
        ),
        GoRoute(
          path: RouterPaths.home,
          builder: (_, _) => const Scaffold(body: Text('shell')),
        ),
        GoRoute(
          path: RouterPaths.teamChat,
          builder: (_, _) => const Text('bare-team'),
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

  testWidgets(
    'returns to the Team chat tab through the shell, not the bare page',
    (tester) async {
      final bloc = await pumpStandaloneRoute(
        tester,
        onBack: (context) =>
            openTeamInMobileShell(context, tab: TeamsMobile.chatTabIndex),
      );

      expect(find.text('shell'), findsOneWidget);
      expect(find.text('bare-team'), findsNothing);
      expect(bloc.state, mobileShellTeamNavIndex);
      expect(TeamsMobile.requestedInitialTab, TeamsMobile.chatTabIndex);
      expect(SondageMobile.requestedInitialTab, 0);
    },
  );

  testWidgets('team list tab does not leave a stale requested tab', (
    tester,
  ) async {
    final bloc = await pumpStandaloneRoute(
      tester,
      onBack: (context) => openTeamInMobileShell(context),
    );

    expect(find.text('shell'), findsOneWidget);
    expect(bloc.state, mobileShellTeamNavIndex);
    expect(TeamsMobile.requestedInitialTab, 0);
  });

  testWidgets('sondage list tab does not leave a stale requested tab', (
    tester,
  ) async {
    final bloc = await pumpStandaloneRoute(
      tester,
      onBack: (context) => openSondageInMobileShell(context),
    );

    expect(find.text('shell'), findsOneWidget);
    expect(bloc.state, mobileShellSondageNavIndex);
    expect(SondageMobile.requestedInitialTab, 0);
  });

  group('legacy chat paths', () {
    test('map /sondage/chat* onto /team/chat*', () {
      expect(
        RouterPaths.legacyChatPaths[RouterPaths.sondageChat],
        RouterPaths.teamChat,
      );
      expect(
        RouterPaths.legacyChatPaths[RouterPaths.sondageChatConversation],
        RouterPaths.teamChatConversation,
      );
    });

    test('redirect keeps the query string', () {
      final target = legacyChatRedirect(
        Uri.parse(
          '/sondage/chat/conversation?teamId=t1&memberUserId=u2&focus=latest',
        ),
        RouterPaths.teamChatConversation,
      );
      expect(
        target,
        '/team/chat/conversation?teamId=t1&memberUserId=u2&focus=latest',
      );
    });

    test('redirect without query has no trailing "?"', () {
      expect(
        legacyChatRedirect(Uri.parse('/sondage/chat'), RouterPaths.teamChat),
        '/team/chat',
      );
    });

    testWidgets('GoRouter follows the legacy alias to the new route', (
      tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/sondage/chat/conversation?teamId=t1',
        routes: [
          GoRoute(
            path: RouterPaths.teamChatConversation,
            builder: (_, state) =>
                Text('team-chat:${state.uri.queryParameters['teamId']}'),
          ),
          GoRoute(
            path: RouterPaths.sondageChatConversation,
            redirect: (_, state) =>
                legacyChatRedirect(state.uri, RouterPaths.teamChatConversation),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      expect(find.text('team-chat:t1'), findsOneWidget);
    });
  });
}
