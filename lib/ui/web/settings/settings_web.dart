import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/bloc/navigation_bloc/navigation_bloc.dart';
import 'package:note_sondage/ui/bloc/navigation_bloc/navigation_event.dart';
import 'package:note_sondage/ui/bloc/setting_Navigation_bloc/setting_navigation_bloc.dart';
import 'package:note_sondage/ui/bloc/setting_Navigation_bloc/setting_navigation_event.dart';
import 'package:note_sondage/ui/web/login/login_web.dart';
import 'package:note_sondage/ui/web/settings/settings_contact_us_web.dart';
import 'package:note_sondage/ui/web/settings/settings_language_web.dart';
import 'package:note_sondage/ui/web/settings/settings_notification_web.dart';
import 'package:note_sondage/ui/web/settings/settings_privacy_web.dart';
import 'package:note_sondage/ui/web/widgets/full_sidebar.dart';
import 'package:note_sondage/ui/web/widgets/home/left_home_section.dart';
import 'package:note_sondage/ui/web/widgets/sidebar_item.dart';

class SettingsWeb extends StatelessWidget {
  const SettingsWeb({super.key, this.child});
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    /* context.read<SettingNavigationBloc>().add(
      SettingNavigationPositionChanged(0),
    );*/
    // final navBarItem = context.watch<NavigationBloc>().state;

    final localizations = AppLocalizations.of(context)!;
    final navBarItem = context.watch<SettingNavigationBloc>().state;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return FullSidebar(
      leftSectionBuilder: (isExpanded, onToggle, lastIndexes) {
        return LeftHomeSection(
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
        );
      },
      rightSection:
          child ??
          Container(
            color: Colors.transparent,
            child: switch (navBarItem) {
              0 => const SettingsLanguageWeb(),
              1 => const SettingsNotificationWeb(),
              2 => const SettingsContactUsWeb(),
              3 => const SettingsPrivacyWeb(),
              4 => const LoginWeb(),
              int() => const SettingsLanguageWeb(),
            },
          ),
      expandedWidth: 200,
      collapsedWidth: 60,
      breakpoint: 400,
    );
  }
}

void showSettingsDialog(BuildContext context, int lastVisitedIndex) {
  showDialog(
    context: context,
    builder: (dialogContext) {
      context.read<SettingNavigationBloc>().add(
        SettingNavigationPositionChanged(0),
      );
      return Dialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
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
    // Se l'utente chiude il dialog senza usare il pulsante di chiusura, torna all'ultima pagina visitata
    if (onValue == null) {
      context.read<NavigationBloc>().add(
        NavigationPositionChanged(lastVisitedIndex),
      );
    }
  });
}
