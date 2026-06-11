import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/ui/mobile/widgets/settings/widgets/theme_selector.dart';
import 'package:note_sondage/ui/widgets/theme_config/bloc/theme/theme_bloc.dart';
import 'package:note_sondage/ui/widgets/theme_config/bloc/theme/theme_event.dart';
import 'package:note_sondage/ui/widgets/theme_config/bloc/theme/theme_state.dart';

class ChangeTheme extends StatelessWidget {
  const ChangeTheme({super.key});

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;

    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        // Determina il tema corrente in base allo state
        String currentTheme = 'light';
        if (state is ThemeisDark) {
          currentTheme = 'dark';
        } else if (state is ThemeisSystem) {
          currentTheme = 'system';
        } else if (state is ThemeisLight) {
          currentTheme = 'light';
        }

        final List<Map<String, dynamic>> themes = [
          {
            'code': 'light',
            'name': localization.lightMode,
            'icon': Icons.light_mode,
            'description': localization.defaultLightTheme,
          },
          {
            'code': 'dark',
            'name': localization.darkMode,
            'icon': Icons.dark_mode,
            'description': localization.darkThemeForLowLight,
          },
          {
            'code': 'system',
            'name': localization.systemDefault,
            'icon': Icons.settings_brightness,
            'description': localization.followSystemSettings,
          },
        ];

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: ThemeSelector(
            themes: themes,
            selectedTheme: currentTheme,
            onThemeChanged: (selected) {
              // Dispatch del corretto evento in base alla selezione
              final themeBloc = context.read<ThemeBloc>();
              if (selected == 'dark') {
                themeBloc.add(const ThemeSetDarkEvent());
              } else if (selected == 'light') {
                themeBloc.add(const ThemeSetLightEvent());
              } else if (selected == 'system') {
                themeBloc.add(const ThemeSetSystemEvent());
              }
            },
          ),
        );
      },
    );
  }
}
