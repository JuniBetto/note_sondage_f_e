import 'package:flutter/material.dart';

class ArchiveViewToggle extends StatelessWidget {
  const ArchiveViewToggle({
    super.key,
    required this.showArchivedOnly,
    required this.primaryCount,
    required this.archivedCount,
    required this.onChanged,
    this.primaryLabel,
    this.archivedLabel,
  });

  final bool showArchivedOnly;
  final int primaryCount;
  final int archivedCount;
  final ValueChanged<bool> onChanged;

  /// Se omesse, vengono usate le etichette predefinite nella lingua dell'app.
  final String? primaryLabel;
  final String? archivedLabel;

  static String defaultPrimaryLabel(BuildContext context) {
    switch (Localizations.localeOf(context).languageCode.toLowerCase()) {
      case 'it':
        return 'In primo piano';
      case 'fr':
        return 'Au premier plan';
      case 'es':
        return 'Destacados';
      default:
        return 'Featured';
    }
  }

  static String defaultArchivedLabel(BuildContext context) {
    switch (Localizations.localeOf(context).languageCode.toLowerCase()) {
      case 'it':
        return 'Archivio';
      case 'fr':
        return 'Archives';
      case 'es':
        return 'Archivo';
      default:
        return 'Archive';
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = primaryLabel ?? defaultPrimaryLabel(context);
    final archived = archivedLabel ?? defaultArchivedLabel(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          label: Text('$primary ($primaryCount)'),
          selected: !showArchivedOnly,
          onSelected: (_) => onChanged(false),
        ),
        ChoiceChip(
          label: Text('$archived ($archivedCount)'),
          selected: showArchivedOnly,
          onSelected: (_) => onChanged(true),
        ),
      ],
    );
  }
}
