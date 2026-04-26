import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:note_sondage/core/config/routes.dart';
import 'package:note_sondage/core/dependency_injection/dependency_injection.dart';
import 'package:note_sondage/feature/auth/ui/bloc/auth_bloc.dart';
import 'package:note_sondage/feature/team/ui/bloc/team/team_bloc.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/bloc/navigation_bloc/navigation_bloc.dart';
import 'package:note_sondage/ui/bloc/navigation_bloc/navigation_event.dart';
import 'package:note_sondage/ui/bloc/setting_Navigation_bloc/setting_navigation_bloc.dart';
import 'package:note_sondage/ui/bloc/setting_Navigation_bloc/setting_navigation_event.dart';
import 'package:note_sondage/ui/web/settings/settings_web.dart';
import 'package:note_sondage/ui/widgets/logout_confirmation_dialog.dart';

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
    // 1. Aggiorna il NavigationBloc — su web l'IndexedStack in MainWeb
    //    reagisce immediatamente senza ricostruire nulla.
    context.read<NavigationBloc>().add(NavigationPositionChanged(index));

    // 2. Gestione della cronologia delle pagine visitate
    if (index != 2) {
      lastIndexes.add(index);
      lastIndexes.length > 5 ? lastIndexes.removeAt(0) : null;
    }

    // 3. Settings (index 2) apre un dialog, niente navigazione.
    if (index == 2) {
      showSettingsDialog(
        context,
        lastIndexes.isNotEmpty ? lastIndexes.last : 0,
      );
      return;
    }

    // 4. Aggiorna anche l'URL del browser via GoRouter.
    //    Su web questo è fondamentale perché altrimenti i pulsanti
    //    back/forward del browser non funzionano (nessuna cronologia).
    //    Su mobile serve per cambiare scaffold.
    switch (index) {
      case 0:
        context.go(RouterPaths.home);
        break;
      case 1:
        context.go(RouterPaths.team);
        break;
      case 3:
        context.go(RouterPaths.clocking);
        break;
      case 4:
        context.go(RouterPaths.sondage);
        break;
    }
  }

  Future<void> _onTapSettings(BuildContext context, int index) async {
    if (index == 4) {
      final shouldLogout = await showLogoutConfirmationDialog(context);
      if (!shouldLogout || !context.mounted) return;

      lastIndexes.add(index);
      lastIndexes.length > 5
          ? lastIndexes.removeAt(0)
          : null; // Mantieni solo gli ultimi 10
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        getIt<TeamBloc>().add(const ResetTeamCacheEvent());
        context.read<AuthBloc>().add(const AuthLogoutRequested());
        GoRouter.of(context).go(RouterPaths.login);
      });
      return;
    }

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
      color: Colors.transparent,
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
