import 'package:flutter/material.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';

class ThemeSelector extends StatelessWidget {
  final List<Map<String, dynamic>> themes;
  final String selectedTheme;
  final Function(String) onThemeChanged;

  const ThemeSelector({
    super.key,
    required this.themes,
    required this.selectedTheme,
    required this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final localization = AppLocalizations.of(context)!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(localization.themeTitle, style: textTheme.headlineMedium),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(30),
          ),
          child: RadioGroup<String>(
            groupValue: selectedTheme,
            onChanged: (value) {
              if (value != null) {
                onThemeChanged(value);
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: themes.map((themeOption) {
                final isSelected = selectedTheme == themeOption['code'];
                return _buildThemeItem(themeOption, isSelected);
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThemeItem(Map<String, dynamic> themeOption, bool isSelected) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: ListTile(
        leading: Radio<String>(value: themeOption['code']),
        title: Text(
          themeOption['name'],
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          themeOption['description'],
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        trailing: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.shade50 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            themeOption['icon'],
            size: 24,
            color: isSelected ? Colors.blue : Colors.grey.shade600,
          ),
        ),
        onTap: () => onThemeChanged(themeOption['code']),
      ),
    );
  }
}
