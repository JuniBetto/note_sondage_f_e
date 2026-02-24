import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:note_sondage/core/config/routes.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';

import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/bloc/navigation_bloc/navigation_bloc.dart';
import 'package:note_sondage/ui/bloc/navigation_bloc/navigation_event.dart';

class LeftHomeSectionNew extends StatelessWidget {
  const LeftHomeSectionNew({super.key, this.isSmallScreen = false});
  final bool isSmallScreen;

  @override
  Widget build(BuildContext context) {
    AppLocalizations localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.bgColorNew,
        borderRadius: BorderRadius.circular(4.0),
        border: Border(
          right: BorderSide(color: colorScheme.borderColor!, width: 2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Row(
                children: [
                  Expanded(
                    child: SvgPicture.asset(
                      'assets/images/logo3.svg',
                      width: 80, // imposta la dimensione che preferisci
                      height: 80,
                      color: colorScheme.selectItem,
                      colorFilter: ColorFilter.mode(
                        colorScheme.selectItem!,
                        BlendMode.srcIn, // Questo modalità cambierà il colore
                      ),
                    ),
                  ),
                  if (isSmallScreen)
                    Expanded(
                      child: Text(
                        "Manage",
                        style: textTheme.headlineLarge!.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.selectItem,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            _SidebarItem(
              key: ValueKey(0),
              icon: Icons.home_outlined,
              label: localizations.home,
              index: 0,
              isSmallScreen: isSmallScreen,
            ),
            _SidebarItem(
              key: ValueKey(1),
              icon: Icons.group,
              label: localizations.team,
              index: 1,
              isSmallScreen: isSmallScreen,
            ),
            /* Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                "Tools :",
                style: textTheme.headlineSmall!.copyWith(
                  decoration: TextDecoration.underline,
                  decorationStyle: TextDecorationStyle.solid,
                  decorationThickness: 4.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),*/
            _SidebarItem(
              key: ValueKey(3),
              icon: Icons.timer,
              label: localizations.clockingInOut,
              index: 3,
              isSmallScreen: isSmallScreen,
            ),
            _SidebarItem(
              key: ValueKey(4),
              icon: Icons.checklist,
              label: localizations.sondage,
              isSmallScreen: isSmallScreen,
              index: 4,
            ),
            const Spacer(),
            Divider(),
            _SidebarItem(
              key: ValueKey(2),
              icon: Icons.settings,
              label: localizations.settings,
              index: 2,
              isSmallScreen: isSmallScreen,
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final bool isSmallScreen;

  const _SidebarItem({
    Key? key,
    required this.icon,
    required this.label,
    required this.index,
    required this.isSmallScreen,
  }) : super(key: key);

  void _onTap(BuildContext context, int index) {
    // 1. Invoca il Cubit per aggiornare la posizione
    context.read<NavigationBloc>().add(NavigationPositionChanged(index));

    // 2. Navigazione con GoRouter
    switch (index) {
      case 0:
        // context.go() sostituisce la pila.
        // Usare context.go(path) è più corretto per la navigazione principale
        context.go(RouterPaths.home);
        break;
      case 1:
        // context.go() sostituisce la pila.
        // Usare context.go(path) è più corretto per la navigazione principale
        context.go(RouterPaths.team);
        break;
      case 2:
        context.go(RouterPaths.settings);
        break;
      case 3:
        context.go(RouterPaths.clocking);
        break;
      case 4:
        context.go(RouterPaths.sondage);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final navBarItem = context.watch<NavigationBloc>().state;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    return Material(
      child: ListTile(
        leading: Icon(
          icon,
          color: navBarItem == index ? colorScheme.textInvertedColor : null,
          size: isSmallScreen ? (navBarItem == index ? 14 : 16) : 24,
        ),
        title: isSmallScreen
            ? Text(
                label,
                style:
                    (navBarItem == index
                            ? textTheme.bodyMedium
                            : textTheme.bodySmall)
                        ?.copyWith(
                          color: navBarItem == index
                              ? colorScheme.textInvertedColor
                              : null,
                        ),
              )
            : null,
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        visualDensity: VisualDensity.compact,
        tileColor: navBarItem == index ? colorScheme.bgsecondary : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onTap: () => _onTap(context, index),
      ),
    );
  }
}
