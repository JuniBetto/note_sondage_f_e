import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_sondage/core/tutorial/app_tutorial_controller.dart';
import 'package:note_sondage/feature/auth/ui/bloc/auth_bloc.dart';
import 'package:note_sondage/feature/clocking/ui/mobile/clocking_shift_tab_page.dart';
import 'package:note_sondage/feature/sondage/ui/mobile/widgets/sondage_mobile.dart';
import 'package:note_sondage/feature/team/ui/mobile/teams_mobile.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/bloc/navigation_bloc/navigation_bloc.dart';
import 'package:note_sondage/ui/mobile/widgets/header_page.dart';
import 'package:note_sondage/ui/mobile/widgets/home/home_dashboard_mobile.dart';
import 'package:note_sondage/ui/mobile/widgets/settings/settings_mobile.dart';
import 'package:note_sondage/ui/widgets/navigation_bar.dart';
import 'package:showcaseview/showcaseview.dart';

class MainMobile extends StatefulWidget {
  const MainMobile({super.key});

  @override
  State<MainMobile> createState() => _MainMobileState();
}

class _MainMobileState extends State<MainMobile> {
  final GlobalKey _bodyKey = GlobalKey();
  final GlobalKey _navigationBarKey = GlobalKey();

  int? _lastScheduledNavIndex;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context)!;
    final navBarItem = context.watch<NavigationBloc>().state;

    _scheduleTutorialForIndex(navBarItem);

    final body = switch (navBarItem) {
      1 => const TeamsMobile(),
      2 => const SettingsMobile(),
      3 => const ClockingShiftTabPage(),
      4 => const SondageMobile(),
      int() => const HomeDashboardMobile(),
    };

    return BlocListener<NavigationBloc, int>(
      listenWhen: (previous, current) => previous != current,
      listener: (context, navIndex) {
        _scheduleTutorialForIndex(navIndex);
      },
      child: Scaffold(
        appBar: HeaderPage(
          showBackButton: false,
          title: switch (navBarItem) {
            1 => loc.team,
            2 => loc.settings,
            3 => loc.clockingInOut,
            4 => loc.sondage,
            int() => loc.home,
          },
        ),
        backgroundColor: colorScheme.homePrimary,
        body: Showcase(
          key: _bodyKey,
          title: _pageTitle(loc, navBarItem),
          description: _pageDescription(context, navBarItem),
          child: body,
        ),
        bottomNavigationBar: Showcase(
          key: _navigationBarKey,
          title: _navigationTitle(context, loc),
          description: _navigationDescription(context),
          child: const NavigationBarWidget(key: Key('mobile_navigation_bar')),
        ),
      ),
    );
  }

  void _scheduleTutorialForIndex(int navIndex) {
    if (!_supportsTutorial(navIndex) || _lastScheduledNavIndex == navIndex) {
      return;
    }

    _lastScheduledNavIndex = navIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }

      await AppTutorialController.showIfNeeded(
        context: context,
        tutorialId: 'mobile-main-$navIndex',
        userId: context.read<AuthBloc>().state.user.uid,
        keys: <GlobalKey>[_bodyKey, _navigationBarKey],
      );
    });
  }

  bool _supportsTutorial(int navIndex) {
    return navIndex == 0 || navIndex == 1 || navIndex == 3 || navIndex == 4;
  }

  String _pageTitle(AppLocalizations localizations, int navIndex) {
    return switch (navIndex) {
      1 => localizations.team,
      3 => localizations.clockingInOut,
      4 => localizations.sondage,
      _ => localizations.home,
    };
  }

  String _pageDescription(BuildContext context, int navIndex) {
    final isItalian = _isItalian(context);
    return switch (navIndex) {
      1 =>
        isItalian
            ? 'Qui puoi esplorare i team, aprire i dettagli e gestire la collaborazione.'
            : 'Explore teams, open details, and manage collaboration from here.',
      3 =>
        isItalian
            ? 'Questa area ti aiuta a registrare la presenza e controllare rapidamente lo stato della giornata.'
            : 'Use this area to track attendance and quickly review your current workday status.',
      4 =>
        isItalian
            ? 'Qui trovi i sondaggi disponibili e puoi seguirne l\'avanzamento.'
            : 'Review available surveys here and keep an eye on their progress.',
      _ =>
        isItalian
            ? 'Questa schermata ti offre una panoramica rapida delle informazioni più importanti.'
            : 'This screen gives you a quick overview of the most important information.',
    };
  }

  String _navigationTitle(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    if (_isItalian(context)) {
      return 'Navigazione';
    }

    return 'Navigation';
  }

  String _navigationDescription(BuildContext context) {
    if (_isItalian(context)) {
      return 'Usa questa barra in basso per passare velocemente tra le sezioni principali dell\'app.';
    }

    return 'Use the bottom bar to move quickly between the main sections of the app.';
  }

  bool _isItalian(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'it';
  }
}
