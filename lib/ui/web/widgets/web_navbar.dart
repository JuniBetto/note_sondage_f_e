import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/ui/bloc/navigation_bloc/navigation_bloc.dart';
import 'package:note_sondage/ui/bloc/navigation_bloc/navigation_event.dart';
import 'package:note_sondage/ui/widgets/custom_app_button.dart';
import 'package:note_sondage/ui/widgets/theme_config/bloc/theme/theme_bloc.dart';
import 'package:note_sondage/ui/widgets/theme_config/bloc/theme/theme_event.dart';
import 'package:note_sondage/ui/widgets/theme_config/bloc/theme/theme_state.dart';
import 'package:note_sondage/ui/widgets/theme_config/custom_toggle_switch.dart';

import '../../widgets/aspect_ratio.dart' as adaptive;

class WebNavbar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? toggleIcon;
  final bool? isVisible;

  // Il costruttore non riceve più isDarkMode o onToggle
  const WebNavbar({super.key, this.toggleIcon, this.isVisible = true});

  void _onTap(BuildContext context, int index) {
    // 1. Invoca il Cubit per aggiornare la posizione
    context.read<NavigationBloc>().add(NavigationPositionChanged(index));

    // 2. Navigazione con GoRouter
    switch (index) {
      case 0:
        // context.go() sostituisce la pila.
        // Usare context.go(path) è più corretto per la navigazione principale
        //context.go(RouterPaths.home);
        break;
      case 1:
        // context.go() sostituisce la pila.
        // Usare context.go(path) è più corretto per la navigazione principale
        //context.go(RouterPaths.home);
        break;
      case 2:
        //context.go(RouterPaths.settings);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Otteniamo il BLoC e lo stato qui, usando 'watch'
    // 'context.watch' fa sì che la navbar si ricostruisca
    // quando lo stato del tema cambia.
    final themeBloc = context.watch<ThemeBloc>();
    final currentState = themeBloc.state;
    final bool isDarkMode = currentState is ThemeisDark;
    final localization = AppLocalizations.of(context)!;
    final navBarItem = context.watch<NavigationBloc>().state;

    // 2. Restituiamo la AppBar
    return AppBar(
      key: const ValueKey("web_navbar"),
      leading: adaptive.AspectRatio(
        aspectRatio: 1,
        borderRadius: BorderRadius.circular( 24),
        child: Image.asset(
          'assets/images/logo.png',
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      ),
      actions: [
        Visibility(
          visible: isVisible!,
          child: Row(
            children: [
              CustomAppButton(
                type: ButtonType.text,
                isActive: navBarItem == 0,
                child: Text(localization.home),
                onPressed: () => _onTap(context, 0),
              ),
              SizedBox(width: 16.0),
              CustomAppButton(
                type: ButtonType.text,
                isActive: navBarItem == 1,
                child: Text(localization.team),
                onPressed: () => _onTap(context, 1),
              ),
              SizedBox(width: 16.0),
              CustomAppButton(
                type: ButtonType.text,
                isActive: navBarItem == 3,
                child: Text(localization.about),
                onPressed: () => _onTap(context, 3),
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16.0,
          ), // Aggiunge spazio
          child:
              toggleIcon ??
              CustomToggleSwitch(
                key: ValueKey("theme_toggle"),
                value: isDarkMode, // <-- Usa lo stato ottenuto dal BLoC
                onChanged: (value) {
                  // 3. Chiamiamo il BLoC direttamente (ORA FUNZIONERÀ)
                  if (currentState is ThemeisLight) {
                    themeBloc.add(ThemeSetDarkEvent());
                  } else if (currentState is ThemeisDark) {
                    themeBloc.add(ThemeSetLightEvent());
                  }
                },
              ),
        ),
      ],
    );
  }

  // 4. Dobbiamo implementare 'preferredSize'
  //    perché siamo un PreferredSizeWidget (requisito per le AppBar)
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
