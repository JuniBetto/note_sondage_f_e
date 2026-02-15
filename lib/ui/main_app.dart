import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:note_sondage/core/config/routes.dart';
import 'package:note_sondage/core/dependency_injection/dependency_injection.dart';
import 'package:note_sondage/feature/team/domain/repositories/permission_repository.dart';
import 'package:note_sondage/feature/team/domain/use_case/permission/permission_use_case.dart';
import 'package:note_sondage/feature/team/ui/bloc/permission/permission_bloc.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/languages/l10n/l10n.dart';
import 'package:note_sondage/ui/bloc/auth_bloc/auth_bloc.dart';
import 'package:note_sondage/ui/bloc/navigation_bloc/navigation_bloc.dart';
import 'package:note_sondage/ui/widgets/theme_config/bloc/theme/theme_bloc.dart';
import 'package:note_sondage/ui/widgets/theme_config/bloc/theme/theme_state.dart';

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  GoRouter? _router;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeBloc>(create: (context) => ThemeBloc()),
        BlocProvider<AuthBloc>(create: (context) => AuthBloc()),
        BlocProvider<NavigationBloc>(create: (context) => NavigationBloc()),
        BlocProvider<RoleBloc>(create: (context) => getIt<RoleBloc>()),
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, state) {
          return Builder(
            builder: (innerContext) {
              _router ??= createRouter(innerContext);

              return MaterialApp.router(
                title: 'Flutter Demo',
                debugShowCheckedModeBanner: false,
                routerConfig: _router,
                theme: state.themeData,
                themeMode: ThemeMode.system,
                supportedLocales: L10n.all,
                locale: const Locale('en'),
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                //home: kIsWeb ? MainWeb() : MainMobile(),
                //home: kIsWeb ? LoginWeb() : LoginMobile(),
              );
            },
          );
        },
      ),
    );
  }
}
