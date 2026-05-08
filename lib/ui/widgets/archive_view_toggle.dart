import 'package:flutter/material.dart';

class ArchiveViewToggle extends StatelessWidget {
  const ArchiveViewToggle({
    super.key,
    required this.showArchivedOnly,
    required this.primaryCount,
    required this.archivedCount,
    required this.onChanged,
    this.primaryLabel = 'In primo piano',
    this.archivedLabel = 'Archivio',
  });

  final bool showArchivedOnly;
  final int primaryCount;
  final int archivedCount;
  final ValueChanged<bool> onChanged;
  final String primaryLabel;
  final String archivedLabel;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          label: Text('$primaryLabel ($primaryCount)'),
          selected: !showArchivedOnly,
          onSelected: (_) => onChanged(false),
        ),
        ChoiceChip(
          label: Text('$archivedLabel ($archivedCount)'),
          selected: showArchivedOnly,
          onSelected: (_) => onChanged(true),
        ),
      ],
    );
  }
}
