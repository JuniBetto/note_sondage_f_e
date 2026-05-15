import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_sondage/core/tutorial/app_tutorial_controller.dart';
import 'package:note_sondage/feature/auth/ui/bloc/auth_bloc.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/bloc/navigation_bloc/navigation_bloc.dart';
import 'package:note_sondage/ui/bloc/navigation_bloc/navigation_event.dart';
import 'package:note_sondage/ui/bloc/setting_Navigation_bloc/setting_navigation_bloc.dart';
import 'package:note_sondage/ui/bloc/setting_Navigation_bloc/setting_navigation_event.dart';
import 'package:note_sondage/ui/web/settings/settings_contact_us_web.dart';
import 'package:note_sondage/ui/web/settings/settings_language_web.dart';
import 'package:note_sondage/ui/web/settings/settings_notification_web.dart';
import 'package:note_sondage/ui/web/settings/settings_privacy_web.dart';
import 'package:note_sondage/ui/web/settings/settings_profile_web.dart';
import 'package:note_sondage/ui/web/widgets/full_sidebar.dart';
import 'package:note_sondage/ui/web/widgets/home/left_home_section.dart';
import 'package:note_sondage/ui/web/widgets/sidebar_item.dart';
import 'package:note_sondage/ui/widgets/auth/contact_email_setup_card.dart';
import 'package:note_sondage/ui/widgets/authenticated_user_summary_card.dart';
import 'package:showcaseview/showcaseview.dart';

class SettingsWeb extends StatefulWidget {
  const SettingsWeb({super.key, this.child});

  final Widget? child;

  @override
  State<SettingsWeb> createState() => _SettingsWebState();
}

class _SettingsWebState extends State<SettingsWeb> {
  final GlobalKey _profileCardKey = GlobalKey();
  final GlobalKey _menuKey = GlobalKey();
  final GlobalKey _contentKey = GlobalKey();

  int? _lastScheduledTab;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final navBarItem = context.watch<SettingNavigationBloc>().state;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    AppTutorialController.registerTargets(
      tutorialId: 'web-settings-$navBarItem',
      keys: <GlobalKey>[_profileCardKey, _menuKey, _contentKey],
    );
    AppTutorialController.registerReplayAction(
      tutorialId: 'web-settings-$navBarItem',
      action: () => AppTutorialController.replay(
        context: context,
        keys: <GlobalKey>[_profileCardKey, _menuKey, _contentKey],
      ),
    );

    _scheduleTutorialForTab(navBarItem);

    return BlocListener<SettingNavigationBloc, int>(
      listenWhen: (previous, current) => previous != current,
      listener: (context, tabIndex) {
        _scheduleTutorialForTab(tabIndex);
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Showcase(
              key: _profileCardKey,
              title: _profileTitle(context),
              description: _profileDescription(context),
              child: AuthenticatedUserSummaryCard(
                onTap: () {
                  context.read<SettingNavigationBloc>().add(
                    SettingNavigationPositionChanged(5),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            const ContactEmailSetupCard(compact: true),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: _replayTutorial,
                icon: const Icon(Icons.help_outline_rounded, size: 18),
                label: Text(localizations.reviewTutorial),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: FullSidebar(
                leftSectionBuilder: (isExpanded, onToggle, lastIndexes) {
                  return Showcase(
                    key: _menuKey,
                    title: _menuTitle(context),
                    description: _menuDescription(context),
                    child: LeftHomeSection(
                      title: Row(
                        children: [
                          Icon(
                            Icons.settings,
                            color: colorScheme.selectItem,
                            size: isExpanded ? 28 : 42,
                          ),
                          if (isExpanded) ...[
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                localizations.settings,
                                style: textTheme.headlineSmall!.copyWith(
                                  fontWeight: FontWeight.w400,
                                  color: colorScheme.selectItem,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      isSmallScreen: isExpanded,
                      onPressedResizeSidebar: onToggle,
                      listSidebarItem: [
                        SidebarItem(
                          isSettings: true,
                          key: const ValueKey(0),
                          icon: Icons.language,
                          label: localizations.language,
                          index: 0,
                          isSmallScreen: isExpanded,
                          lastIndexes: lastIndexes,
                        ),
                        SidebarItem(
                          isSettings: true,
                          key: const ValueKey(1),
                          icon: Icons.notifications,
                          label: localizations.notification,
                          index: 1,
                          isSmallScreen: isExpanded,
                          lastIndexes: lastIndexes,
                        ),
                        SidebarItem(
                          isSettings: true,
                          key: const ValueKey(2),
                          icon: Icons.contacts,
                          label: localizations.contactUs,
                          index: 2,
                          isSmallScreen: isExpanded,
                          lastIndexes: lastIndexes,
                        ),
                        const Spacer(),
                        SidebarItem(
                          isSettings: true,
                          key: const ValueKey(3),
                          icon: Icons.privacy_tip,
                          label: localizations.privacy,
                          index: 3,
                          isSmallScreen: isExpanded,
                          lastIndexes: lastIndexes,
                        ),
                        SidebarItem(
                          isSettings: true,
                          key: const ValueKey(4),
                          icon: Icons.logout_outlined,
                          label: localizations.logout,
                          index: 4,
                          isSmallScreen: isExpanded,
                          lastIndexes: lastIndexes,
                        ),
                      ],
                    ),
                  );
                },
                rightSection: Showcase(
                  key: _contentKey,
                  title: _contentTitle(context, localizations, navBarItem),
                  description: _contentDescription(context, navBarItem),
                  child:
                      widget.child ??
                      ColoredBox(
                        color: Colors.transparent,
                        child: switch (navBarItem) {
                          5 => const SettingsProfileWeb(),
                          0 => const SettingsLanguageWeb(),
                          1 => const SettingsNotificationWeb(),
                          2 => const SettingsContactUsWeb(),
                          3 => const SettingsPrivacyWeb(),
                          int() => const SettingsLanguageWeb(),
                        },
                      ),
                ),
                expandedWidth: 200,
                collapsedWidth: 60,
                breakpoint: 400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _scheduleTutorialForTab(int tabIndex) {
    if (!_supportsTutorial(tabIndex) || _lastScheduledTab == tabIndex) {
      return;
    }

    _lastScheduledTab = tabIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }

      await AppTutorialController.showIfNeeded(
        context: context,
        tutorialId: 'web-settings-$tabIndex',
        userId: context.read<AuthBloc>().state.user.uid,
        keys: <GlobalKey>[_profileCardKey, _menuKey, _contentKey],
      );
    });
  }

  void _replayTutorial() {
    AppTutorialController.replayRegistered(
      context: context,
      tutorialId: 'web-settings-${context.read<SettingNavigationBloc>().state}',
    );
  }

  bool _supportsTutorial(int tabIndex) {
    return tabIndex == 0 ||
        tabIndex == 1 ||
        tabIndex == 2 ||
        tabIndex == 3 ||
        tabIndex == 5;
  }

  String _profileTitle(BuildContext context) {
    if (_isItalian(context)) {
      return 'Profilo';
    }

    return 'Profile';
  }

  String _profileDescription(BuildContext context) {
    if (_isItalian(context)) {
      return 'Da qui puoi aprire il profilo e aggiornare i dati principali del tuo account.';
    }

    return 'Open your profile here to update the most important account details.';
  }

  String _menuTitle(BuildContext context) {
    if (_isItalian(context)) {
      return 'Menu impostazioni';
    }

    return 'Settings menu';
  }

  String _menuDescription(BuildContext context) {
    if (_isItalian(context)) {
      return 'Questa colonna ti permette di passare rapidamente tra lingua, notifiche, privacy e supporto.';
    }

    return 'Use this column to move quickly between language, notifications, privacy, and support.';
  }

  String _contentTitle(
    BuildContext context,
    AppLocalizations localizations,
    int tabIndex,
  ) {
    return switch (tabIndex) {
      1 => localizations.notification,
      2 => localizations.contactUs,
      3 => localizations.privacy,
      5 => _isItalian(context) ? 'Profilo account' : 'Account profile',
      _ => localizations.language,
    };
  }

  String _contentDescription(BuildContext context, int tabIndex) {
    final isItalian = _isItalian(context);
    return switch (tabIndex) {
      1 =>
        isItalian
            ? 'Qui decidi come ricevere aggiornamenti e avvisi importanti.'
            : 'Choose here how you want to receive important updates and alerts.',
      2 =>
        isItalian
            ? 'Questa area raccoglie i canali utili per contattare il supporto.'
            : 'This area gathers the best ways to contact support.',
      3 =>
        isItalian
            ? 'Qui puoi consultare le informazioni legate a privacy e protezione dei dati.'
            : 'Review privacy and data protection information in this section.',
      5 =>
        isItalian
            ? 'Qui puoi aggiornare profilo, sicurezza e preferenze personali.'
            : 'Update your profile, security, and personal preferences from here.',
      _ =>
        isItalian
            ? 'Da qui puoi scegliere la lingua più comoda per usare l\'app.'
            : 'Choose the language that feels most comfortable for using the app.',
    };
  }

  bool _isItalian(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'it';
  }
}

void showSettingsDialog(BuildContext context, int lastVisitedIndex) {
  final settingNavigationBloc = context.read<SettingNavigationBloc>();
  final navigationBloc = context.read<NavigationBloc>();
  final surfaceColor = Theme.of(context).colorScheme.surface;

  showDialog(
    context: context,
    builder: (dialogContext) {
      settingNavigationBloc.add(SettingNavigationPositionChanged(0));
      return Dialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: FractionallySizedBox(
          widthFactor: 0.85,
          heightFactor: 0.85,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: const SettingsWeb(),
          ),
        ),
      );
    },
  ).then((onValue) {
    if (onValue == null) {
      navigationBloc.add(NavigationPositionChanged(lastVisitedIndex));
    }
  });
}
