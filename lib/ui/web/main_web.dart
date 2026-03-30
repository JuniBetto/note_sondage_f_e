import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_sondage/feature/clocking/ui/web/clocking_web.dart';
import 'package:note_sondage/feature/sondage/ui/web/sondage_web.dart';
import 'package:note_sondage/feature/team/ui/web/teams_web.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/bloc/navigation_bloc/navigation_bloc.dart';
import 'package:note_sondage/ui/mobile/widgets/home/home_mobile.dart';
import 'package:note_sondage/ui/web/widgets/full_sidebar.dart';
import 'package:note_sondage/ui/web/widgets/home/left_home_section.dart';
import 'package:note_sondage/ui/web/widgets/sidebar_item.dart';
import 'package:note_sondage/ui/widgets/theme_config/bloc/theme/theme_bloc.dart';
import 'package:note_sondage/ui/widgets/theme_config/bloc/theme/theme_event.dart';
import 'package:note_sondage/ui/widgets/theme_config/bloc/theme/theme_state.dart';
import 'package:note_sondage/ui/widgets/theme_config/custom_toggle_switch.dart';

/// Le 4 pagine principali, pre-costruite una sola volta.
/// IndexedStack le tiene tutte in memoria e mostra solo quella attiva
/// → cambio istantaneo senza ricostruire nulla.
const _pages = <Widget>[
  HomeMobile(), // index 0
  TeamsWeb(), // index 1
  SizedBox.shrink(), // index 2 (settings = dialog, niente pagina)
  ClockingWeb(), // index 3
  SondageWeb(), // index 4
];

class MainWeb extends StatelessWidget {
  const MainWeb({super.key, this.child});
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final localizations = AppLocalizations.of(context)!;
    final themeBloc = context.watch<ThemeBloc>();
    final currentState = themeBloc.state;
    final bool isDarkMode = currentState is ThemeisDark;

    return Scaffold(
      backgroundColor: colorScheme.homePrimary,
      body: FullSidebar(
        leftSectionBuilder: (isExpanded, onToggle, lastIndexes) {
          return LeftHomeSection(
            isSmallScreen: isExpanded,
            onPressedResizeSidebar: onToggle,
            listSidebarItem: [
              SidebarItem(
                key: const ValueKey(0),
                icon: Icons.home_outlined,
                label: localizations.home,
                index: 0,
                isSmallScreen: isExpanded,
                lastIndexes: lastIndexes,
              ),
              SidebarItem(
                key: const ValueKey(1),
                icon: Icons.group,
                label: localizations.team,
                index: 1,
                isSmallScreen: isExpanded,
                lastIndexes: lastIndexes,
              ),
              SidebarItem(
                key: const ValueKey(3),
                icon: Icons.timer,
                label: localizations.clockingInOut,
                index: 3,
                isSmallScreen: isExpanded,
                lastIndexes: lastIndexes,
              ),
              SidebarItem(
                key: const ValueKey(4),
                icon: Icons.checklist,
                label: localizations.sondage,
                index: 4,
                isSmallScreen: isExpanded,
                lastIndexes: lastIndexes,
              ),
              const Spacer(),
              Row(
                children: [
                  if (isExpanded)
                    Text(
                      isDarkMode ? "Dark Mode : " : "Light Mode : ",
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: colorScheme.selectItem,
                      ),
                    ),
                  Expanded(
                    child: CustomToggleSwitch(
                      key: ValueKey("theme_toggle"),
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
        // Se un child è passato (es. da GoRouter per rolePage / updateTeam),
        // mostralo direttamente. Altrimenti usa IndexedStack per le pagine
        // principali — zero rebuild al cambio tab.
        rightSection:
            child ??
            BlocBuilder<NavigationBloc, int>(
              builder: (context, navIndex) {
                // Clamp index per evitare out-of-range
                final safeIndex = navIndex.clamp(0, _pages.length - 1);
                return IndexedStack(index: safeIndex, children: _pages);
              },
            ),
      ),
    );
  }
}
