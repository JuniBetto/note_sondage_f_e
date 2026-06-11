import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:note_sondage/core/config/routes.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/theme.dart';

Widget buildTestApp({
  required Widget child,
  ThemeData? theme,
  Locale locale = const Locale('it'),
}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: theme ?? AppTheme.buildTheme(false),
    home: Scaffold(body: Center(child: child)),
  );
}

Widget buildRouterTestApp({
  required Widget child,
  ThemeData? theme,
  Locale locale = const Locale('it'),
}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(body: Center(child: child)),
      ),
      GoRoute(
        path: RouterPaths.updateTeam,
        builder: (context, state) =>
            const Scaffold(body: Text('Update team page')),
      ),
    ],
  );

  return MaterialApp.router(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: theme ?? AppTheme.buildTheme(false),
    routerConfig: router,
  );
}
