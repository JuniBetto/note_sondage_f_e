import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:note_sondage/feature/chat/ui/mobile/chat_mobile_conversation_page.dart';
import 'package:note_sondage/feature/chat/ui/web/chat_web_page.dart';
import 'package:note_sondage/feature/clocking/ui/mobile/clocking_mobile.dart';
import 'package:note_sondage/feature/shift/ui/bloc/shift_bloc.dart';
import 'package:note_sondage/feature/shift/ui/mobile/shift_mobile_page.dart';
import 'package:note_sondage/feature/sondage/ui/mobile/sondage_detail_mobile.dart';
import 'package:note_sondage/feature/sondage/ui/mobile/widgets/sondage_mobile.dart';
import 'package:note_sondage/feature/sondage/ui/web/sondage_detail_web.dart';
import 'package:note_sondage/feature/team/ui/mobile/role_page.dart';
import 'package:note_sondage/feature/team/ui/mobile/teams_mobile.dart';
import 'package:note_sondage/feature/team/ui/mobile/update_team_mobile.dart';
import 'package:note_sondage/feature/team/ui/web/role_page_web.dart';
import 'package:note_sondage/feature/team/ui/web/widgets/update_team_web.dart';
import 'package:note_sondage/feature/auth/domain/entities/auth_user_entity.dart';
import 'package:note_sondage/feature/auth/ui/bloc/auth_bloc.dart';
import 'package:note_sondage/ui/bloc/navigation_bloc/navigation_bloc.dart';
import 'package:note_sondage/ui/bloc/navigation_bloc/navigation_event.dart';
import 'package:note_sondage/ui/mobile/main_mobile.dart';
import 'package:note_sondage/ui/mobile/widgets/login/login_mobile.dart';
import 'package:note_sondage/ui/mobile/widgets/settings/settings_mobile.dart';
import 'package:note_sondage/ui/web/login/login_web.dart';
import 'package:note_sondage/ui/web/main_web.dart';
import 'package:note_sondage/ui/web/settings/settings_contact_us_web.dart';
import 'package:note_sondage/ui/web/settings/settings_language_web.dart';
import 'package:note_sondage/ui/web/settings/settings_notification_web.dart';
import 'package:note_sondage/ui/web/settings/settings_privacy_web.dart';
import 'package:note_sondage/ui/web/settings/settings_web.dart';
import 'package:note_sondage/ui/app_keys.dart';
import 'package:note_sondage/ui/widgets/about_page.dart';
import 'package:note_sondage/ui/widgets/auth/confirm_account_deletion_page.dart';
import 'package:note_sondage/ui/widgets/auth/confirm_account_reactivation_page.dart';
import 'package:note_sondage/ui/widgets/auth/confirm_registration_page.dart';
import 'package:note_sondage/ui/widgets/auth/reset_password_page.dart';
import 'package:note_sondage/ui/widgets/splash_screen/splash_sreen_begin.dart';

//String currentAppPath = RouterPaths.splashScreen;

final _rootNavigatorKey = navigatorKey;
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// Mappa il path URL all'indice dell'IndexedStack nel NavigationBloc.
/// Usato per sincronizzare il bloc quando il browser naviga (back/forward).
int _pathToNavIndex(String path) {
  switch (path) {
    case RouterPaths.home:
      return 0;
    case RouterPaths.team:
      return 1;
    case RouterPaths.clocking:
      return 3;
    case RouterPaths.sondage:
      return 4;
    case RouterPaths.shifts:
      return 5;
    case RouterPaths.chat:
      return 6;
    default:
      return 0;
  }
}

GoRouter createRouter(BuildContext context) {
  final authBloc = context.read<AuthBloc>(); // Ottiene l'istanza del BLoC

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    routes: [
      // =====================
      // 🔒 WEB — ShellRoute: MainWeb rimane stabile.
      // Le 4 pagine principali (Home/Team/Clocking/Sondage) sono dentro un
      // IndexedStack in MainWeb, gestito dal NavigationBloc → zero rebuild.
      // GoRouter serve solo per le route secondarie (rolePage, updateTeam, etc.)
      // =====================
      if (kIsWeb)
        ShellRoute(
          navigatorKey: _shellNavigatorKey,
          pageBuilder: (context, state, child) {
            // child è SizedBox.shrink per la home (IndexedStack gestisce),
            // oppure il widget della route secondaria (rolePage, etc.)
            final path = state.uri.path;
            final isMainPage =
                path == RouterPaths.home ||
                path == RouterPaths.team ||
                path == RouterPaths.clocking ||
                path == RouterPaths.sondage ||
                path == RouterPaths.shifts;

            // ═══ Sincronizza il NavigationBloc con l'URL corrente ═══
            // Fondamentale per i pulsanti back/forward del browser:
            // GoRouter aggiorna il path, ma senza questo l'IndexedStack
            // resterebbe fermo sull'indice precedente.
            if (isMainPage || path == RouterPaths.chat) {
              final targetIndex = _pathToNavIndex(path);
              final navBloc = context.read<NavigationBloc>();
              if (navBloc.state != targetIndex) {
                navBloc.add(NavigationPositionChanged(targetIndex));
              }
            }

            return NoTransitionPage<void>(
              child: MainWeb(child: isMainPage ? null : child),
            );
          },
          routes: [
            // Home è il punto di ingresso — IndexedStack gestisce la vista
            GoRoute(
              path: RouterPaths.home,
              name: RouterPaths.home,
              pageBuilder: (context, state) =>
                  const NoTransitionPage<void>(child: SizedBox.shrink()),
            ),
            // Queste route servono per il redirect (es. da login → home)
            // e per aggiornare l'URL nel browser
            GoRoute(
              path: RouterPaths.team,
              name: RouterPaths.team,
              pageBuilder: (context, state) =>
                  const NoTransitionPage<void>(child: SizedBox.shrink()),
            ),
            GoRoute(
              path: RouterPaths.clocking,
              name: RouterPaths.clocking,
              pageBuilder: (context, state) =>
                  const NoTransitionPage<void>(child: SizedBox.shrink()),
            ),
            GoRoute(
              path: RouterPaths.sondage,
              name: RouterPaths.sondage,
              pageBuilder: (context, state) =>
                  const NoTransitionPage<void>(child: SizedBox.shrink()),
            ),
            GoRoute(
              path: RouterPaths.shifts,
              name: RouterPaths.shifts,
              pageBuilder: (context, state) =>
                  const NoTransitionPage<void>(child: SizedBox.shrink()),
            ),
            GoRoute(
              path: RouterPaths.chat,
              name: RouterPaths.chat,
              pageBuilder: (context, state) => NoTransitionPage<void>(
                child: ChatWebPage(
                  initialTeamId: state.uri.queryParameters['teamId'],
                  initialMemberUserId:
                      state.uri.queryParameters['memberUserId'],
                  initialMemberName: state.uri.queryParameters['memberName'],
                  focusLatestOnOpen:
                      state.uri.queryParameters['focus'] == 'latest',
                ),
              ),
            ),
            // Route secondarie — queste passano il child a MainWeb
            GoRoute(
              path: RouterPaths.rolePage,
              name: RouterPaths.rolePage,
              pageBuilder: (context, state) {
                final teamId = state.extra as String? ?? '';
                return NoTransitionPage<void>(
                  child: RolePageWeb(teamId: teamId),
                );
              },
            ),
            GoRoute(
              path: RouterPaths.permissionPage,
              name: RouterPaths.permissionPage,
              pageBuilder: (context, state) {
                final teamId = state.extra as String? ?? '';
                return NoTransitionPage<void>(
                  child: RolePageWeb(teamId: teamId),
                );
              },
            ),
            GoRoute(
              path: RouterPaths.updateTeam,
              name: RouterPaths.updateTeam,
              pageBuilder: (context, state) => NoTransitionPage<void>(
                child: UpdateTeamWeb(
                  teamId: state.extra as String?,
                  readOnly: true,
                ),
              ),
            ),
            GoRoute(
              path: RouterPaths.teamDetail,
              name: RouterPaths.teamDetail,
              pageBuilder: (context, state) => NoTransitionPage<void>(
                child: UpdateTeamWeb(
                  teamId: state.extra as String?,
                  readOnly: true,
                ),
              ),
            ),
            GoRoute(
              path: RouterPaths.sondageDetail,
              name: RouterPaths.sondageDetail,
              pageBuilder: (context, state) {
                final sondageId = state.extra as String? ?? '';
                return NoTransitionPage<void>(
                  child: SondageDetailWeb(sondageId: sondageId),
                );
              },
            ),
            GoRoute(
              path: RouterPaths.settings,
              name: RouterPaths.settings,
              pageBuilder: (context, state) =>
                  const NoTransitionPage<void>(child: SettingsWeb()),
              routes: [
                GoRoute(
                  path: 'language',
                  name: RouterPaths.settingsLanguage,
                  pageBuilder: (context, state) => const NoTransitionPage<void>(
                    child: SettingsLanguageWeb(),
                  ),
                ),
                GoRoute(
                  path: 'notifications',
                  name: RouterPaths.settingsNotifications,
                  pageBuilder: (context, state) => const NoTransitionPage<void>(
                    child: SettingsNotificationWeb(),
                  ),
                ),
                GoRoute(
                  path: 'contact_us',
                  name: RouterPaths.settingsContactUs,
                  pageBuilder: (context, state) => const NoTransitionPage<void>(
                    child: SettingsContactUsWeb(),
                  ),
                ),
                GoRoute(
                  path: 'privacy',
                  name: RouterPaths.settingsPrivacy,
                  pageBuilder: (context, state) =>
                      const NoTransitionPage<void>(child: SettingsPrivacyWeb()),
                ),
              ],
            ),
          ],
        ),

      // =====================
      // 📱 MOBILE routes (no shell needed, each has its own scaffold)
      // =====================
      if (!kIsWeb) ...[
        GoRoute(
          path: RouterPaths.home,
          name: RouterPaths.home,
          pageBuilder: (context, state) =>
              const NoTransitionPage<void>(child: MainMobile()),
        ),
        GoRoute(
          path: RouterPaths.team,
          name: RouterPaths.team,
          pageBuilder: (context, state) =>
              const NoTransitionPage<void>(child: TeamsMobile()),
        ),
        GoRoute(
          path: RouterPaths.clocking,
          name: RouterPaths.clocking,
          pageBuilder: (context, state) =>
              const NoTransitionPage<void>(child: ClockingMobile()),
        ),
        GoRoute(
          path: RouterPaths.sondage,
          name: RouterPaths.sondage,
          pageBuilder: (context, state) =>
              const NoTransitionPage<void>(child: SondageMobile()),
        ),
        GoRoute(
          path: RouterPaths.sondageChat,
          name: RouterPaths.sondageChat,
          pageBuilder: (context, state) => NoTransitionPage<void>(
            child: SondageMobile(
              initialTabIndex: 2,
              initialChatTeamId: state.uri.queryParameters['teamId'],
            ),
          ),
        ),
        GoRoute(
          path: RouterPaths.sondageChatConversation,
          name: RouterPaths.sondageChatConversation,
          pageBuilder: (context, state) {
            final teamId = state.uri.queryParameters['teamId']?.trim();
            if (teamId == null || teamId.isEmpty) {
              return const NoTransitionPage<void>(
                child: SondageMobile(initialTabIndex: 2),
              );
            }
            return NoTransitionPage<void>(
              child: ChatMobileConversationPage(
                teamId: teamId,
                memberUserId: state.uri.queryParameters['memberUserId'],
                memberName: state.uri.queryParameters['memberName'],
                focusLatestOnOpen:
                    state.uri.queryParameters['focus'] == 'latest',
              ),
            );
          },
        ),
        GoRoute(
          path: RouterPaths.shifts,
          name: RouterPaths.shifts,
          pageBuilder: (context, state) => NoTransitionPage<void>(
            child: BlocProvider<ShiftBloc>.value(
              value: GetIt.instance<ShiftBloc>(),
              child: const ShiftMobilePage(),
            ),
          ),
        ),
        GoRoute(
          path: RouterPaths.rolePage,
          name: RouterPaths.rolePage,
          pageBuilder: (context, state) {
            final teamId = state.extra as String? ?? '';
            return NoTransitionPage<void>(child: RolePage(teamId: teamId));
          },
        ),
        GoRoute(
          path: RouterPaths.permissionPage,
          name: RouterPaths.permissionPage,
          pageBuilder: (context, state) {
            final teamId = state.extra as String? ?? '';
            return NoTransitionPage<void>(child: RolePage(teamId: teamId));
          },
        ),
        GoRoute(
          path: RouterPaths.updateTeam,
          name: RouterPaths.updateTeam,
          pageBuilder: (context, state) => NoTransitionPage<void>(
            child: UpdateTeamMobile(teamId: state.extra as String?),
          ),
        ),
        GoRoute(
          path: RouterPaths.teamDetail,
          name: RouterPaths.teamDetail,
          pageBuilder: (context, state) => NoTransitionPage<void>(
            child: UpdateTeamMobile(
              teamId: state.extra as String?,
              readOnly: true,
            ),
          ),
        ),
        GoRoute(
          path: RouterPaths.sondageDetail,
          name: RouterPaths.sondageDetail,
          pageBuilder: (context, state) {
            final sondageId = state.extra as String? ?? '';
            return NoTransitionPage<void>(
              child: SondageDetailMobile(sondageId: sondageId),
            );
          },
        ),
        GoRoute(
          path: RouterPaths.settings,
          name: RouterPaths.settings,
          pageBuilder: (context, state) =>
              const NoTransitionPage<void>(child: SettingsMobile()),
          routes: [
            GoRoute(
              path: 'language',
              name: RouterPaths.settingsLanguage,
              pageBuilder: (context, state) => const NoTransitionPage<void>(
                child: LoginMobile(isForgetPassword: true),
              ),
            ),
            GoRoute(
              path: 'notifications',
              name: RouterPaths.settingsNotifications,
              pageBuilder: (context, state) => const NoTransitionPage<void>(
                child: LoginMobile(isForgetPassword: true),
              ),
            ),
            GoRoute(
              path: 'contact_us',
              name: RouterPaths.settingsContactUs,
              pageBuilder: (context, state) => const NoTransitionPage<void>(
                child: LoginMobile(isForgetPassword: true),
              ),
            ),
            GoRoute(
              path: 'privacy',
              name: RouterPaths.settingsPrivacy,
              pageBuilder: (context, state) => const NoTransitionPage<void>(
                child: LoginMobile(isForgetPassword: true),
              ),
            ),
          ],
        ),
      ],

      // =====================
      // 🔓 PUBLIC ROUTES (shared between web and mobile)
      // =====================
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
        path: RouterPaths.confirmRegistration,
        name: RouterPaths.confirmRegistration,
        pageBuilder: (context, state) => NoTransitionPage<void>(
          child: ConfirmRegistrationPage(
            queryParameters: state.uri.queryParameters,
          ),
        ),
      ),
      GoRoute(
        path: RouterPaths.resetPassword,
        name: RouterPaths.resetPassword,
        pageBuilder: (context, state) => NoTransitionPage<void>(
          child: ResetPasswordPage(queryParameters: state.uri.queryParameters),
        ),
      ),
      GoRoute(
        path: RouterPaths.confirmAccountDeletion,
        name: RouterPaths.confirmAccountDeletion,
        pageBuilder: (context, state) => NoTransitionPage<void>(
          child: ConfirmAccountDeletionPage(
            queryParameters: state.uri.queryParameters,
          ),
        ),
      ),
      GoRoute(
        path: RouterPaths.confirmAccountReactivation,
        name: RouterPaths.confirmAccountReactivation,
        pageBuilder: (context, state) => NoTransitionPage<void>(
          child: ConfirmAccountReactivationPage(
            queryParameters: state.uri.queryParameters,
          ),
        ),
      ),
      GoRoute(
        path: RouterPaths.splashScreen,
        name: RouterPaths.splashScreen,
        pageBuilder: (context, state) =>
            const NoTransitionPage<void>(child: SplashScreenBegin()),
      ),
      GoRoute(
        path: RouterPaths.login,
        pageBuilder: (context, state) => NoTransitionPage<void>(
          child: kIsWeb
              ? LoginWeb(queryParameters: state.uri.queryParameters)
              : LoginMobile(queryParameters: state.uri.queryParameters),
        ),
      ),
    ],
    redirect: (context, state) {
      final isAuthenticated = authBloc.isAuthenticated;
      final currentPath = state.fullPath;

      final isGuestOnlyRoute =
          currentPath == RouterPaths.login ||
          currentPath == RouterPaths.splashScreen ||
          currentPath == RouterPaths.forgotPassword;

      final isPublicRoute =
          isGuestOnlyRoute ||
          currentPath == RouterPaths.confirmRegistration ||
          currentPath == RouterPaths.confirmAccountDeletion ||
          currentPath == RouterPaths.confirmAccountReactivation ||
          currentPath == RouterPaths.resetPassword;

      // 0. Operazione in corso (login/register/SSO): non toccare la rotta
      if (authBloc.state.status == AuthStatus.loading) {
        return null;
      }

      // 1. Se lo stato di autenticazione è SCONOSCIUTO, mostra splash screen
      if (authBloc.state.status == AuthStatus.unknown) {
        return RouterPaths.splashScreen;
      }
      // 2. Se l'utente è loggato (Authenticated):
      if (isAuthenticated) {
        // Se è su una rotta pubblica (login o splash), reindirizza a home
        return isGuestOnlyRoute ? RouterPaths.home : null;
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
  static const confirmRegistration = '/confirm-registration';
  static const confirmAccountDeletion = '/confirm-account-deletion';
  static const confirmAccountReactivation = '/confirm-account-reactivation';
  static const resetPassword = '/reset-password';
  static const team = '/team';
  static const forgotPassword = '/forgot_password';
  static const splashScreen = '/splash_screen';
  static const settings = '/settings';
  static const settingsLanguage = '/settings/language';
  static const settingsNotifications = '/settings/notifications';
  static const settingsPrivacy = '/settings/privacy';
  static const settingsContactUs = '/settings/contact_us';
  static const clocking = '/clocking';
  static const sondage = '/sondage';
  static const sondageChat = '/sondage/chat';
  static const sondageChatConversation = '/sondage/chat/conversation';
  static const shifts = '/shifts';
  static const chat = '/chat';
  static const createTeam = '/create_team';
  static const updateTeam = '/update_team';
  static const teamDetail = '/team_detail';
  static const permissionPage = '/permission_page';
  static const rolePage = '/role_page';
  static const sondageDetail = '/sondage_detail';
}
