import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  "Select your language",
                  style: textTheme.headlineMedium,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: LanguageSelector(
                  isMobile: false,
                  languages: languagesToSelect,
                  selectedLanguages: [state.locale.languageCode],
                  onSelectionChanged: (selected) {
                    if (selected.isNotEmpty) {
                      // Dispatch del evento per cambiare lingua
                      context.read<LanguageBloc>().add(
                            LanguageChangeEvent(selected.first),
                          );
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
