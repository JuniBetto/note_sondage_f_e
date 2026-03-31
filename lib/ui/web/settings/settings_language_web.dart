import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/mobile/widgets/settings/widgets/language_selected.dart';
import 'package:note_sondage/ui/widgets/language_config/bloc/language_bloc.dart';
import 'package:note_sondage/ui/widgets/language_config/bloc/language_event.dart';
import 'package:note_sondage/ui/widgets/language_config/bloc/language_state.dart';

class SettingsLanguageWeb extends StatelessWidget {
  const SettingsLanguageWeb({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final localization = AppLocalizations.of(context)!;

    return BlocBuilder<LanguageBloc, LanguageState>(
      builder: (context, state) {
        final List<Map<String, dynamic>> languagesToSelect = [
          {
            'code': 'en',
            'name': 'English',
            'flagPath': 'assets/images/flags/england.svg',
          },
          {
            'code': 'it',
            'name': 'Italian',
            'flagPath': 'assets/images/flags/italia.svg',
          },
          {
            'code': 'es',
            'name': 'Spanish',
            'flagPath': 'assets/images/flags/spain.svg',
          },
          {
            'code': 'fr',
            'name': 'French',
            'flagPath': 'assets/images/flags/france.svg',
          },
        ];

        return Align(
          alignment: Alignment.topLeft,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2196F3).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.language_rounded,
                        color: Color(0xFF2196F3),
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localization.selectYourLanguage,
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Choose your preferred language for the application',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.descriptionColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Current language info
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.selectItem!.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.selectItem!.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: colorScheme.selectItem,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Current: ${_getLanguageName(state.locale.languageCode)}',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.selectItem,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Language selector
                LanguageSelector(
                  isMobile: false,
                  languages: languagesToSelect,
                  selectedLanguages: [state.locale.languageCode],
                  onSelectionChanged: (selected) {
                    if (selected.isNotEmpty) {
                      context.read<LanguageBloc>().add(
                        LanguageChangeEvent(selected.first),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'it':
        return 'Italiano';
      case 'es':
        return 'Español';
      case 'fr':
        return 'Français';
      default:
        return 'English';
    }
  }
}
