import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/color_palette.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/bloc/navigation_bloc/navigation_bloc.dart';
import 'package:note_sondage/ui/bloc/navigation_bloc/navigation_event.dart';

class NavigationBarWidget extends StatelessWidget {
  const NavigationBarWidget({super.key});

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
        //context.go(RouterPaths.settings);
        break;
      case 2:
        //context.go(RouterPaths.settings);
        break;
      case 3:
        //context.go(RouterPaths.settings);
        break;
      case 4:
        //context.go(RouterPaths.settings);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // === BLOC: Sostituisce ref.watch(navigationControllerProvider) ===
    // Ascolta lo stato del Cubit per ottenere la posizione corrente
    final position = context.watch<NavigationBloc>().state;

    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        //color: colorScheme.bgSurface,
        border: Border(
          top: BorderSide(
            color: colorScheme.borderColor!,
            width: 2,
          ),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          selectedLabelStyle: textTheme.labelMedium!.copyWith(
            backgroundColor: ColorPalette.primary[6],
          ),
          unselectedLabelStyle: textTheme.labelMedium,
          currentIndex: position,

          // === BLOC: Sostituisce _onTap(context, ref, index) ===
          onTap: (index) => _onTap(context, index),

          selectedItemColor: ColorPalette.primary[6],
          unselectedItemColor: colorScheme.onSurfaceVariant,
          items: [
            BottomNavigationBarItem(
              icon: _buildSectionTitle(
                context,
                const Icon(Icons.home_outlined),
                Text(l10n.home),
              ),
              activeIcon: _buildSectionTitle(
                context,
                const Icon(Icons.home),
                Text(
                  l10n.home,
                  style: textTheme.labelMedium!.copyWith(
                    color: colorScheme.textInvertedColor,
                  ),
                ),
                isActive: position == 0,
              ),
              label: '', //l10n.home,
              tooltip: l10n.home,
            ),
            BottomNavigationBarItem(
              icon: _buildSectionTitle(
                context,
                Icon(Icons.people_outlined,
                  //color: colorScheme.textInvertedColor,
                ),
                Text(l10n.team),
              ),
              activeIcon: _buildSectionTitle(
                context,
                const Icon(Icons.people_alt_rounded),
                Text(
                  l10n.team,
                  style: textTheme.labelMedium!.copyWith(
                    color: colorScheme.textInvertedColor,
                  ),
                ),
                isActive: position == 1,
              ),
              label: '', //l10n.team,
              tooltip: l10n.team,
            ),
            BottomNavigationBarItem(
              icon: _buildSectionTitle(
                context,
                const Icon(Icons.settings_outlined),
                Text(l10n.settings),
              ),
              activeIcon: _buildSectionTitle(
                context,
                const Icon(Icons.settings),
                Text(
                  l10n.settings,
                  style: textTheme.labelMedium!.copyWith(
                    color: colorScheme.textInvertedColor,
                  ),
                ),
                isActive: position == 2,
              ),
              label: '', //l10n.settings,
              tooltip: l10n.settings,
            ),
            BottomNavigationBarItem(
              icon: _buildSectionTitle(
                context,
                const Icon(Icons.timer_outlined),
                Text(l10n.clockingInOut),
              ),
              activeIcon: _buildSectionTitle(
                context,
                const Icon(Icons.timer),
                Text(
                  l10n.clockingInOut,
                  style: textTheme.labelMedium!.copyWith(
                    color: colorScheme.textInvertedColor,
                  ),
                ),
                isActive: position == 3,
              ),
              label: '', //l10n.settings,
              tooltip: l10n.clockingInOut,
            ),
            BottomNavigationBarItem(
              icon: _buildSectionTitle(
                context,
                const Icon(Icons.list_alt_outlined),
                Text(l10n.sondage),
              ),
              activeIcon: _buildSectionTitle(
                context,
                const Icon(Icons.list_alt),
                Text(
                  l10n.sondage,
                  style: textTheme.labelMedium!.copyWith(
                    color: colorScheme.textInvertedColor,
                  ),
                ),
                isActive: position == 4,
              ),
              label: '', //l10n.settings,
              tooltip: l10n.sondage,
            ),
          ],
        ),
      ),
    );
  }
}

// Funzione helper non ha bisogno di modifiche
Widget _buildSectionTitle(
  BuildContext context,
  Widget icon,
  Widget? label, {
  bool isActive = false,
}) {
  return Column(
    children: [
      icon,
      DecoratedBox(
        decoration: BoxDecoration(
          color: isActive ? ColorPalette.primary[6] : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(padding: const EdgeInsets.all(4.0), child: label),
      ),
    ],
  );
}
