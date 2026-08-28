import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_sondage/core/tutorial/app_tutorial_controller.dart';
import 'package:note_sondage/feature/auth/ui/bloc/auth_bloc.dart';
import 'package:note_sondage/feature/clocking/ui/mobile/clocking_shift_tab_page.dart';
import 'package:note_sondage/feature/sondage/ui/mobile/widgets/sondage_mobile.dart';
import 'package:note_sondage/feature/team/ui/mobile/teams_mobile.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/bloc/navigation_bloc/navigation_bloc.dart';
import 'package:note_sondage/ui/mobile/widgets/home/home_dashboard_mobile.dart';
import 'package:note_sondage/ui/mobile/widgets/settings/settings_mobile.dart';
import 'package:note_sondage/ui/widgets/navigation_bar.dart';
import 'package:note_sondage/core/tutorial/debug_showcase.dart';

import '../bloc/navigation_bloc/navigation_event.dart';

class MainMobile extends StatefulWidget {
  const MainMobile({super.key});

  @override
  State<MainMobile> createState() => _MainMobileState();
}

class _MainMobileState extends State<MainMobile> {
  static const MethodChannel _lifecycleChannel = MethodChannel(
    'com.arthbet.noteSondage/app_lifecycle',
  );
  final GlobalKey _bodyKey = GlobalKey();
  final GlobalKey _navigationBarKey = GlobalKey();

  int? _lastScheduledNavIndex;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context)!;
    final navBarItem = context.watch<NavigationBloc>().state;

    if (!_isDelegatedTutorialIndex(navBarItem)) {
      AppTutorialController.registerTargets(
        tutorialId: 'mobile-main-$navBarItem',
        keys: <GlobalKey>[_bodyKey, _navigationBarKey],
      );
      AppTutorialController.registerReplayAction(
        tutorialId: 'mobile-main-$navBarItem',
        action: () => AppTutorialController.replay(
          context: context,
          keys: <GlobalKey>[_bodyKey, _navigationBarKey],
        ),
      );
    }

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
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) {
            return;
          }
          unawaited(_handleAndroidBack());
        },
        child: Scaffold(
          backgroundColor: colorScheme.homePrimary,
          extendBody: true,
          body: SafeArea(
            bottom: false,
            child: _buildShowcase(
              showcaseKey: _bodyKey,
              title: _pageTitle(loc, navBarItem),
              description: _pageDescription(context, navBarItem),
              child: body,
            ),
          ),
          bottomNavigationBar: _buildShowcase(
            showcaseKey: _navigationBarKey,
            title: _navigationTitle(context, loc),
            description: _navigationDescription(context),
            child: const NavigationBarWidget(key: Key('mobile_navigation_bar')),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
          // Stesso widget (IconButton.filledTonal) usato dal bottone "?"
          // flottante su web, così i due si allineano per colore/stile.
          floatingActionButton: _supportsTutorial(navBarItem)
              ? Tooltip(
                  message: loc.reviewTutorial,
                  child: IconButton.filledTonal(
                    onPressed: () => _replayTutorialForIndex(navBarItem),
                    icon: const Icon(Icons.help_outline_rounded),
                  ),
                )
              : null,
        ),
      ),
    );
  }

  Future<void> _handleAndroidBack() async {
    if (Theme.of(context).platform != TargetPlatform.android) {
      return;
    }

    if (AppTutorialController.dismissActiveTutorialIfAny()) {
      return;
    }

    final navigator = Navigator.of(context, rootNavigator: true);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }

    final navBloc = context.read<NavigationBloc>();
    if (navBloc.state != 0) {
      navBloc.add(NavigationPositionChanged(0));
      return;
    }

    final movedToBack =
        await _lifecycleChannel.invokeMethod<bool>('moveTaskToBack') ?? false;
    if (!movedToBack) {
      await SystemNavigator.pop();
    }
  }

  Widget _buildShowcase({
    required GlobalKey showcaseKey,
    required String title,
    required String description,
    required Widget child,
  }) {
    if (_shouldBypassShowcaseInDebug()) {
      return child;
    }

    return Showcase(
      key: showcaseKey,
      title: title,
      description: description,
      child: child,
    );
  }

  void _scheduleTutorialForIndex(int navIndex) {
    if (!_supportsTutorial(navIndex) ||
        _isDelegatedTutorialIndex(navIndex) ||
        _lastScheduledNavIndex == navIndex) {
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

  void _replayTutorialForIndex(int navIndex) {
    if (!_supportsTutorial(navIndex)) {
      return;
    }
    if (navIndex == 2) {
      AppTutorialController.replayRegistered(
        context: context,
        tutorialId: 'mobile-settings',
      );
      return;
    }
    AppTutorialController.replayRegistered(
      context: context,
      tutorialId: 'mobile-main-$navIndex',
    );
  }

  bool _supportsTutorial(int navIndex) {
    return navIndex == 0 ||
        navIndex == 1 ||
        navIndex == 2 ||
        navIndex == 3 ||
        navIndex == 4;
  }

  bool _isDelegatedTutorialIndex(int navIndex) {
    return navIndex == 1 || navIndex == 3 || navIndex == 4;
  }

  String _pageTitle(AppLocalizations localizations, int navIndex) {
    return switch (navIndex) {
      1 => localizations.team,
      3 => localizations.planningTabLabel,
      4 => localizations.sondageChat,
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
            ? 'Qui trovi turni, task, eventi e timbrature: tutto ciò che serve per pianificare e seguire la tua giornata di lavoro.'
            : 'Here you can find shifts, tasks, events, and clocking: everything you need to plan and track your workday.',
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

  bool _shouldBypassShowcaseInDebug() {
    return isInspectorSelectionActive;
  }
}
