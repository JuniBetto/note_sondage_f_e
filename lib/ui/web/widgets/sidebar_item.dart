import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:note_sondage/core/config/routes.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/bloc/navigation_bloc/navigation_bloc.dart';
import 'package:note_sondage/ui/bloc/navigation_bloc/navigation_event.dart';
import 'package:note_sondage/ui/bloc/setting_Navigation_bloc/setting_navigation_bloc.dart';
import 'package:note_sondage/ui/bloc/setting_Navigation_bloc/setting_navigation_event.dart';
import 'package:note_sondage/ui/web/settings/settings_web.dart';

class SidebarItem extends StatelessWidget {
  final bool isSettings;
  final IconData icon;
  final String label;
  final int index;
  final bool isSmallScreen;
  final List<int> lastIndexes;

  const SidebarItem({
    super.key,
    required this.icon,
    required this.label,
    required this.index,
    required this.isSmallScreen,
    required this.lastIndexes,
    this.isSettings = false,
  });

  void _onTap(BuildContext context, int index) {
    // 1. Invoca il Cubit per aggiornare la posizione
    context.read<NavigationBloc>().add(NavigationPositionChanged(index));

    // 2. Gestione della cronologia delle pagine visitate
    // Solo le pagine diverse da Settings (index 2) vengono aggiunte alla cronologia
    if (index != 2) {
      lastIndexes.add(index);
      lastIndexes.length > 5
          ? lastIndexes.removeAt(0)
          : null; // Mantieni solo gli ultimi 10
    }

    // 3. Navigazione con GoRouter
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
        showSettingsDialog(
          context,
          lastIndexes.isNotEmpty ? lastIndexes.last : 0,
        );
        break;
      case 3:
        context.go(RouterPaths.clocking);
        break;
      case 4:
        context.go(RouterPaths.sondage);
        break;
    }
  }

  void _onTapSettings(BuildContext context, int index) {
    // 1. Invoca il Cubit per aggiornare la posizione
    context.read<SettingNavigationBloc>().add(
      SettingNavigationPositionChanged(index),
    );

    // 2. NON navigare con GoRouter quando siamo nel dialog delle settings
    // Il cambio di stato del bloc farà aggiornare la rightSection automaticamente
  }

  @override
  Widget build(BuildContext context) {
    // Usa il bloc corretto in base al tipo di sidebar
    final navBarItem = isSettings
        ? context.watch<SettingNavigationBloc>().state
        : context.watch<NavigationBloc>().state;
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
        onTap: () => isSettings
            ? _onTapSettings(context, index)
            : _onTap(context, index),
      ),
    );
  }
}
