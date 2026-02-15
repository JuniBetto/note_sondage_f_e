import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:note_sondage/core/config/routes.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';

import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/bloc/navigation_bloc/navigation_bloc.dart';
import 'package:note_sondage/ui/bloc/navigation_bloc/navigation_event.dart';

class LeftHomeSection extends StatelessWidget {
  const LeftHomeSection({super.key});

  @override
  Widget build(BuildContext context) {
    AppLocalizations localizations = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.bgColor!.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4.0),
        /* border: Border(
          right: BorderSide(
            color: Theme.of(context).colorScheme.borderColor!,
            width: 4,
          ),
        ),*/
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SidebarItem(
              key: ValueKey(0),
              icon: Icons.home,
              label: localizations.home,
              index: 0,
            ),
            _SidebarItem(
              key: ValueKey(1),
              icon: Icons.group,
              label: localizations.team,
              index: 1,
            ),
            Divider(),
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
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _SidebarItem(
                key: ValueKey(5),
                icon: Icons.timer,
                label: localizations.clockingInOut,
                index: 5,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _SidebarItem(
                key: ValueKey(6),
                icon: Icons.checklist,
                label: localizations.sondage,
                index: 6,
              ),
            ),
            const Spacer(),
            Divider(),
            _SidebarItem(
              key: ValueKey(2),
              icon: Icons.settings,
              label: localizations.settings,
              index: 2,
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

  const _SidebarItem({
    Key? key,
    required this.icon,
    required this.label,
    required this.index,
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
      case 5:
        context.go(RouterPaths.clocking);
        break;
      case 6:
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
    return ListTile(
      leading: Icon(
        icon,
        color: navBarItem == index ? colorScheme.textInvertedColor : null,
      ),
      title: Text(
        label,
        style: textTheme.bodyLarge?.copyWith(
          color: navBarItem == index ? colorScheme.textInvertedColor : null,
        ),
      ),
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      visualDensity: VisualDensity.compact,
      tileColor: navBarItem == index ? colorScheme.bgsecondary : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: () => _onTap(context, index),
    );
  }
}
