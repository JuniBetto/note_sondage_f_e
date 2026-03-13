import 'package:flutter/material.dart';
import 'package:note_sondage/ui/mobile/widgets/settings/widgets/language_selected.dart';

class ChangeLanguage extends StatefulWidget {
  const ChangeLanguage({super.key});

  @override
  State<ChangeLanguage> createState() => _ChangeLanguageState();
}

class _ChangeLanguageState extends State<ChangeLanguage> {
  List<String> _selectedLanguages = ['en'];
  final List<Map<String, dynamic>> _languages = [
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: LanguageSelector(
        languages: _languages,
        selectedLanguages: _selectedLanguages,
        onSelectionChanged: (selected) {
          print('Selected languages: $selected');
          _selectedLanguages = selected;
        },
      ),
    );
  }
}
