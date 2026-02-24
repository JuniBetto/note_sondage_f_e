import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:note_sondage/feature/clocking/ui/mobile/clocking_mobile.dart';
import 'package:note_sondage/feature/clocking/ui/web/clocking_web.dart';
import 'package:note_sondage/feature/sondage/ui/mobile/widgets/sondage_mobile.dart';
import 'package:note_sondage/feature/sondage/ui/web/sondage_web.dart';
import 'package:note_sondage/feature/team/ui/mobile/role_page.dart';
import 'package:note_sondage/feature/team/ui/mobile/teams_mobile.dart';
import 'package:note_sondage/feature/team/ui/mobile/widgets/create_team_mobile.dart';
import 'package:note_sondage/feature/team/ui/mobile/update_team_mobile.dart';
import 'package:note_sondage/feature/team/ui/web/role_page_web.dart';
import 'package:note_sondage/feature/team/ui/web/teams_web.dart';
import 'package:note_sondage/feature/team/ui/web/widgets/create_team_web.dart';
import 'package:note_sondage/feature/team/ui/web/widgets/update_team_web.dart';
import 'package:note_sondage/ui/bloc/auth_bloc/auth_bloc.dart';
import 'package:note_sondage/ui/bloc/auth_bloc/auth_state.dart';
import 'package:note_sondage/ui/mobile/main_mobile.dart';
import 'package:note_sondage/ui/mobile/widgets/login/login_mobile.dart';
import 'package:note_sondage/ui/mobile/widgets/settings/settings_mobile.dart';
import 'package:note_sondage/ui/web/login/login_web.dart';
import 'package:note_sondage/ui/web/main_web.dart';
import 'package:note_sondage/ui/web/main_web_new.dart';
import 'package:note_sondage/ui/web/settings/settings_web.dart';
import 'package:note_sondage/ui/widgets/about_page.dart';
import 'package:note_sondage/ui/widgets/splash_screen/splash_sreen_begin.dart';
import 'package:note_sondage/ui/widgets/team_page.dart';

//String currentAppPath = RouterPaths.splashScreen;

final _rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createRouter(BuildContext context) {
  final authBloc = context.read<AuthBloc>(); // Ottiene l'istanza del BLoC

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    //initialLocation: currentAppPath,
    // observers: [GoRouterObserver()],
    routes: [
      GoRoute(
        path: RouterPaths.settings,
        name: RouterPaths.settings,
        pageBuilder: (context, state) => const NoTransitionPage<void>(
          child: kIsWeb ? MainWeb(child: SettingsWeb()) : SettingsMobile(),
        ),
      ),
      GoRoute(
        path: RouterPaths.forgotPassword,
        name: RouterPaths.forgotPassword,
        pageBuilder: (context, state) => const NoTransitionPage<void>(
          child: kIsWeb
              ? LoginWeb(isForgetPassword: true)
              : LoginMobile(isForgetPassword: true),
        ),
      ),
      GoRoute(
        path: RouterPaths.about,
        name: RouterPaths.about,
        pageBuilder: (context, state) =>
            const NoTransitionPage<void>(child: AboutPage()),
      ),
      GoRoute(
        path: RouterPaths.sondage,
        name: RouterPaths.sondage,
        pageBuilder: (context, state) => const NoTransitionPage<void>(
          child: kIsWeb ? MainWeb(child: SondageWeb()) : SondageMobile(),
        ),
      ),
      GoRoute(
        path: RouterPaths.clocking,
        name: RouterPaths.clocking,
        pageBuilder: (context, state) => const NoTransitionPage<void>(
          child: kIsWeb ? MainWeb(child: ClockingWeb()) : ClockingMobile(),
        ),
      ),
      GoRoute(
        path: RouterPaths.team,
        name: RouterPaths.team,
        pageBuilder: (context, state) => const NoTransitionPage<void>(
          child: kIsWeb ? MainWeb(child: TeamsWeb()) : TeamsMobile(),
        ),
      ),
      GoRoute(
        path: RouterPaths.splashScreen,
        name: RouterPaths.splashScreen,
        pageBuilder: (context, state) =>
            const NoTransitionPage<void>(child: SplashScreenBegin()),
      ),
      GoRoute(
        path: RouterPaths.home,
        name: RouterPaths.home,
        pageBuilder: (context, state) => const NoTransitionPage<void>(
          child: kIsWeb ? MainWeb() : MainMobile(),
        ),
      ),
      GoRoute(
        path: RouterPaths.rolePage,
        name: RouterPaths.rolePage,
        pageBuilder: (context, state) {
          final teamId = state.extra as String? ?? '';
          return NoTransitionPage<void>(
            child: kIsWeb
                ? MainWeb(child: RolePageWeb(teamId: teamId))
                : RolePage(teamId: teamId),
          );
        },
      ),
      GoRoute(
        path: RouterPaths.permissionPage,
        name: RouterPaths.permissionPage,
        pageBuilder: (context, state) {
          final teamId = state.extra as String? ?? '';
          return NoTransitionPage<void>(
            child: kIsWeb
                ? MainWeb(child: RolePageWeb(teamId: teamId))
                : RolePage(teamId: teamId),
          );
        },
      ),
      GoRoute(
        path: RouterPaths.login,
        pageBuilder: (context, state) => const NoTransitionPage<void>(
          child: kIsWeb ? LoginWeb() : LoginMobile(),
        ),
      ),
      GoRoute(
        path: RouterPaths.updateTeam,
        name: RouterPaths.updateTeam,
        pageBuilder: (context, state) => NoTransitionPage<void>(
          child: kIsWeb
              ? MainWeb(child: UpdateTeamWeb(teamId: state.extra as String?))
              : UpdateTeamMobile(teamId: state.extra as String?),
        ),
      ),
    ],
    redirect: (context, state) {
      final isAuthenticated = authBloc.isAuthenticated;
      final currentPath = state.fullPath;

      final isPublicRoute =
          currentPath == RouterPaths.login ||
          currentPath ==
              RouterPaths
                  .forgotPassword /*||
          currentPath == RouterPaths.splashScreen*/;

      // 1. Se lo stato di autenticazione è SCONOSCIUTO, mostra splash screen
      if (authBloc.state is AuthUnknown) {
        return RouterPaths.splashScreen;
      }
      // 2. Se l'utente è loggato (Authenticated):
      if (isAuthenticated) {
        // Se è su una rotta pubblica (login o splash), reindirizza a home
        return isPublicRoute ? RouterPaths.home : null;
      }

      // 3. Se l'utente NON è loggato (Unauthenticated):
      if (!isAuthenticated) {
        return isPublicRoute ? null : RouterPaths.login;
      }

      return null;
    },
    // 4. Gestore dei cambiamenti di stato del BLoC (ChangeNotifier)
    // Questo dice a GoRouter di rieseguire la funzione redirect
    // ogni volta che lo stato di AuthBloc cambia.
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
  );
}

/*
final _rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createRouter(BuildContext context) {
  final authBloc = context.read<AuthBloc>();

  return GoRouter(
    navigatorKey: _rootNavigatorKey,

    routes: [
      // =====================
      // 🔒 SHELL (Dashboard)
      // =====================
      ShellRoute(
        builder: (context, state, child) {
          return kIsWeb ? MainWeb() : MainMobile();
        },
        routes: [
          GoRoute(
            path: RouterPaths.home,
            name: RouterPaths.home,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: kIsWeb ? MainWeb() : MainMobile(),
            ),
          ),
          GoRoute(
            path: RouterPaths.team,
            name: RouterPaths.team,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: kIsWeb ? MainWeb(child: TeamsWeb()) : TeamsMobile(),
            ),
          ),
          GoRoute(
            path: RouterPaths.settings,
            name: RouterPaths.settings,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: kIsWeb ? MainWeb(child: SettingsWeb()) : SettingsMobile(),
            ),
          ),
          GoRoute(
            path: RouterPaths.clocking,
            name: RouterPaths.clocking,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: kIsWeb ? MainWeb(child: ClockingWeb()) : ClockingMobile(),
            ),
          ),
          GoRoute(
            path: RouterPaths.sondage,
            name: RouterPaths.sondage,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: kIsWeb ? MainWeb(child: SondageWeb()) : SondageMobile(),
            ),
          ),
        ],
      ),

      // =====================
      // 🔓 PUBLIC ROUTES
      // =====================
      GoRoute(
        path: RouterPaths.login,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: kIsWeb ? LoginWeb() : LoginMobile()),
      ),
      GoRoute(
        path: RouterPaths.forgotPassword,
        pageBuilder: (context, state) => const NoTransitionPage(
          child: kIsWeb
              ? LoginWeb(isForgetPassword: true)
              : LoginMobile(isForgetPassword: true),
        ),
      ),
      GoRoute(
        path: RouterPaths.splashScreen,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: SplashScreenBegin()),
      ),
      GoRoute(
        path: RouterPaths.about,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: AboutPage()),
      ),
    ],

    // =====================
    // 🔁 REDIRECT (INALTERATO)
    // =====================
    redirect: (context, state) {
      final isAuthenticated = authBloc.isAuthenticated;
      final currentPath = state.fullPath;

      final isPublicRoute =
          currentPath == RouterPaths.login ||
          currentPath == RouterPaths.forgotPassword;

      if (authBloc.state is AuthUnknown) {
        return RouterPaths.splashScreen;
      }

      if (isAuthenticated) {
        return isPublicRoute ? RouterPaths.home : null;
      }

      if (!isAuthenticated) {
        return isPublicRoute ? null : RouterPaths.login;
      }

      return null;
    },

    refreshListenable: GoRouterRefreshStream(authBloc.stream),
  );
}*/

// GO ROUTER REFRESH STREAM (Necessario per usare Stream/Bloc con GoRouter)
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

abstract class RouterPaths {
  static const home = '/';
  static const login = '/login';
  static const about = '/about';
  static const team = '/team';
  static const forgotPassword = '/forgot_password';
  static const splashScreen = '/splash_screen';
  static const settings = '/settings';
  static const clocking = '/clocking';
  static const sondage = '/sondage';
  static const createTeam = '/create_team';
  static const updateTeam = '/update_team';
  static const permissionPage = '/permission_page';
  static const rolePage = '/role_page';
}
