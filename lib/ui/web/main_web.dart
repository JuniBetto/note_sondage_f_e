import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:note_sondage/core/tutorial/app_tutorial_controller.dart';
import 'package:note_sondage/feature/auth/ui/bloc/auth_bloc.dart';
import 'package:note_sondage/feature/clocking/ui/web/clocking_web.dart';
import 'package:note_sondage/feature/shift/ui/bloc/shift_bloc.dart';
import 'package:note_sondage/feature/shift/ui/web/shift_web_page.dart';
import 'package:note_sondage/feature/sondage/ui/web/sondage_web.dart';
import 'package:note_sondage/feature/team/ui/web/teams_web.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/bloc/navigation_bloc/navigation_bloc.dart';
import 'package:note_sondage/ui/web/widgets/full_sidebar.dart';
import 'package:note_sondage/ui/web/widgets/home/home_web.dart';
import 'package:note_sondage/ui/web/widgets/home/left_home_section.dart';
import 'package:note_sondage/ui/web/widgets/notification_center_button.dart';
import 'package:note_sondage/ui/web/widgets/sidebar_item.dart';
import 'package:note_sondage/ui/widgets/theme_config/bloc/theme/theme_bloc.dart';
import 'package:note_sondage/ui/widgets/theme_config/bloc/theme/theme_event.dart';
import 'package:note_sondage/ui/widgets/theme_config/bloc/theme/theme_state.dart';
import 'package:note_sondage/ui/widgets/theme_config/custom_toggle_switch.dart';
import 'package:note_sondage/core/tutorial/debug_showcase.dart';

class MainWeb extends StatefulWidget {
  const MainWeb({super.key, this.child});

  final Widget? child;

  @override
  State<MainWeb> createState() => _MainWebState();
}

class _MainWebState extends State<MainWeb> {
  final GlobalKey _homeKey = GlobalKey();
  final GlobalKey _teamKey = GlobalKey();
  final GlobalKey _clockingKey = GlobalKey();
  final GlobalKey _sondageKey = GlobalKey();
  final GlobalKey _shiftsKey = GlobalKey();
  final GlobalKey _contentKey = GlobalKey();
  final GlobalKey _notificationsKey = GlobalKey();

  int? _lastScheduledNavIndex;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final localizations = AppLocalizations.of(context)!;
    final themeBloc = context.watch<ThemeBloc>();
    final currentState = themeBloc.state;
    final bool isDarkMode = currentState is ThemeisDark;
    final currentNavIndex = context.watch<NavigationBloc>().state;

    if (!_isDelegatedTutorialIndex(currentNavIndex)) {
      AppTutorialController.registerTargets(
        tutorialId: 'web-main-$currentNavIndex',
        keys: <GlobalKey>[
          _navigationKeyForIndex(currentNavIndex),
          _contentKey,
          _notificationsKey,
        ],
      );
      AppTutorialController.registerReplayAction(
        tutorialId: 'web-main-$currentNavIndex',
        action: () => AppTutorialController.replay(
          context: context,
          keys: <GlobalKey>[
            _navigationKeyForIndex(currentNavIndex),
            _contentKey,
            _notificationsKey,
          ],
        ),
      );
    }

    _scheduleTutorialForIndex(currentNavIndex);

    return BlocListener<NavigationBloc, int>(
      listenWhen: (previous, current) => previous != current,
      listener: (context, navIndex) {
        _scheduleTutorialForIndex(navIndex);
      },
      child: Scaffold(
        backgroundColor: colorScheme.homePrimary,
        body: FullSidebar(
          leftSectionBuilder: (isExpanded, onToggle, lastIndexes) {
            return LeftHomeSection(
              isSmallScreen: isExpanded,
              onPressedResizeSidebar: onToggle,
              listSidebarItem: [
                _buildShowcase(
                  showcaseKey: _homeKey,
                  title: localizations.home,
                  description: _navDescription(context),
                  child: SidebarItem(
                    key: const ValueKey(0),
                    icon: Icons.home_outlined,
                    label: localizations.home,
                    index: 0,
                    isSmallScreen: isExpanded,
                    lastIndexes: lastIndexes,
                  ),
                ),
                _buildShowcase(
                  showcaseKey: _teamKey,
                  title: localizations.team,
                  description: _navDescription(context),
                  child: SidebarItem(
                    key: const ValueKey(1),
                    icon: Icons.group,
                    label: localizations.team,
                    index: 1,
                    isSmallScreen: isExpanded,
                    lastIndexes: lastIndexes,
                  ),
                ),
                _buildShowcase(
                  showcaseKey: _clockingKey,
                  title: localizations.clockingInOut,
                  description: _navDescription(context),
                  child: SidebarItem(
                    key: const ValueKey(3),
                    icon: Icons.timer,
                    label: localizations.clockingInOut,
                    index: 3,
                    isSmallScreen: isExpanded,
                    lastIndexes: lastIndexes,
                  ),
                ),
                _buildShowcase(
                  showcaseKey: _sondageKey,
                  title: localizations.sondage,
                  description: _navDescription(context),
                  child: SidebarItem(
                    key: const ValueKey(4),
                    icon: Icons.checklist,
                    label: localizations.sondage,
                    index: 4,
                    isSmallScreen: isExpanded,
                    lastIndexes: lastIndexes,
                  ),
                ),
                _buildShowcase(
                  showcaseKey: _shiftsKey,
                  title: localizations.myShifts,
                  description: _navDescription(context),
                  child: SidebarItem(
                    key: const ValueKey(5),
                    icon: Icons.calendar_month_rounded,
                    label: localizations.myShifts,
                    index: 5,
                    isSmallScreen: isExpanded,
                    lastIndexes: lastIndexes,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    if (isExpanded)
                      Text(
                        isDarkMode ? 'Dark Mode : ' : 'Light Mode : ',
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: colorScheme.selectItem,
                        ),
                      ),
                    Expanded(
                      child: CustomToggleSwitch(
                        key: const ValueKey('theme_toggle'),
                        value: isDarkMode,
                        onChanged: (value) {
                          if (currentState is ThemeisLight) {
                            themeBloc.add(ThemeSetDarkEvent());
                          } else if (currentState is ThemeisDark) {
                            themeBloc.add(ThemeSetLightEvent());
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const Divider(),
                SidebarItem(
                  key: const ValueKey(2),
                  icon: Icons.settings,
                  label: localizations.settings,
                  index: 2,
                  isSmallScreen: isExpanded,
                  lastIndexes: lastIndexes,
                ),
              ],
            );
          },
          rightSection: Builder(
            builder: (context) {
              final pages = <Widget>[
                const HomeWeb(),
                const TeamsWeb(),
                const SizedBox.shrink(),
                const ClockingWeb(),
                const SondageWeb(),
                BlocProvider<ShiftBloc>.value(
                  value: GetIt.instance<ShiftBloc>(),
                  child: const ShiftWebPage(),
                ),
              ];

              return Stack(
                fit: StackFit.expand,
                children: [
                  _buildShowcase(
                    showcaseKey: _contentKey,
                    title: _contentTitle(localizations, currentNavIndex),
                    description: _contentDescription(context, currentNavIndex),
                    child: BlocBuilder<NavigationBloc, int>(
                      builder: (context, navIndex) {
                        final safeIndex = navIndex.clamp(0, pages.length - 1);
                        return IndexedStack(index: safeIndex, children: pages);
                      },
                    ),
                  ),
                  if (widget.child != null)
                    Positioned.fill(
                      child: ColoredBox(
                        color: colorScheme.homePrimary ?? colorScheme.surface,
                        child: widget.child!,
                      ),
                    ),
                  Positioned(
                    top: 20,
                    right: 20,
                    child: _buildShowcase(
                      showcaseKey: _notificationsKey,
                      title: localizations.notification,
                      description: _notificationsDescription(context),
                      child: const NotificationCenterButton(),
                    ),
                  ),
                  if (_supportsTutorial(currentNavIndex))
                    Positioned(
                      left: 20,
                      bottom: 20,
                      child: Tooltip(
                        message: localizations.reviewTutorial,
                        child: IconButton.filledTonal(
                          onPressed: () =>
                              _replayTutorialForIndex(currentNavIndex),
                          icon: const Icon(Icons.help_outline_rounded),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
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
        tutorialId: 'web-main-$navIndex',
        userId: context.read<AuthBloc>().state.user.uid,
        keys: <GlobalKey>[
          _navigationKeyForIndex(navIndex),
          _contentKey,
          _notificationsKey,
        ],
      );
    });
  }

  void _replayTutorialForIndex(int navIndex) {
    if (!_supportsTutorial(navIndex)) {
      return;
    }
    AppTutorialController.replayRegistered(
      context: context,
      tutorialId: 'web-main-$navIndex',
    );
  }

  bool _supportsTutorial(int navIndex) {
    return navIndex == 0 ||
        navIndex == 1 ||
        navIndex == 3 ||
        navIndex == 4 ||
        navIndex == 5;
  }

  bool _isDelegatedTutorialIndex(int navIndex) {
    return navIndex == 0 ||
        navIndex == 1 ||
        navIndex == 3 ||
        navIndex == 4 ||
        navIndex == 5;
  }

  bool _shouldBypassShowcaseInDebug() {
    return isInspectorSelectionActive;
  }

  GlobalKey _navigationKeyForIndex(int navIndex) {
    return switch (navIndex) {
      1 => _teamKey,
      3 => _clockingKey,
      4 => _sondageKey,
      5 => _shiftsKey,
      _ => _homeKey,
    };
  }

  String _contentTitle(AppLocalizations localizations, int navIndex) {
    return switch (navIndex) {
      1 => localizations.team,
      3 => localizations.clockingInOut,
      4 => localizations.sondage,
      5 => localizations.myShifts,
      _ => localizations.home,
    };
  }

  String _navDescription(BuildContext context) {
    if (_isItalian(context)) {
      return 'Usa questa barra laterale per spostarti rapidamente tra le aree principali dell\'app.';
    }

    return 'Use this sidebar to move quickly between the main areas of the app.';
  }

  String _notificationsDescription(BuildContext context) {
    if (_isItalian(context)) {
      return 'Qui trovi notifiche, inviti e aggiornamenti importanti senza lasciare la pagina corrente.';
    }

    return 'Your latest alerts, invites, and updates appear here without leaving the current page.';
  }

  String _contentDescription(BuildContext context, int navIndex) {
    final isItalian = _isItalian(context);
    return switch (navIndex) {
      1 =>
        isItalian
            ? 'Qui gestisci i team, i membri e le azioni principali legate alla collaborazione.'
            : 'Manage teams, members, and the main collaboration actions from this area.',
      3 =>
        isItalian
            ? 'Questa sezione ti aiuta a registrare entrate, uscite e pause in modo rapido.'
            : 'Use this section to track clock-ins, clock-outs, and breaks quickly.',
      4 =>
        isItalian
            ? 'Qui trovi i sondaggi, puoi aprirli e seguirne facilmente lo stato.'
            : 'Here you can review surveys, open them, and keep track of their status.',
      5 =>
        isItalian
            ? 'Questa pagina raccoglie i tuoi turni e i relativi dettagli operativi.'
            : 'This page gathers your shifts and their operational details in one place.',
      _ =>
        isItalian
            ? 'La dashboard ti mostra il riepilogo più importante del tuo spazio di lavoro.'
            : 'The dashboard gives you the most important overview of your workspace.',
    };
  }

  bool _isItalian(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'it';
  }
}
