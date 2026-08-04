import 'package:flutter/material.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_auto_plan_entity.dart';

import 'shift_auto_plan_preview_action_support.dart';

class ShiftAutoPlanPreviewLegendCard extends StatelessWidget {
  const ShiftAutoPlanPreviewLegendCard({
    super.key,
    required this.compact,
    required this.title,
    required this.description,
    required this.createLabel,
    required this.preserveLabel,
    required this.deleteLabel,
  });

  final bool compact;
  final String title;
  final String description;
  final String createLabel;
  final String preserveLabel;
  final String deleteLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final createStyle = shiftAutoPlanPreviewActionStyle(
      ShiftAutoPlanPreviewAction.create,
    );
    final preserveStyle = shiftAutoPlanPreviewActionStyle(
      ShiftAutoPlanPreviewAction.preserve,
    );
    final deleteStyle = shiftAutoPlanPreviewActionStyle(
      ShiftAutoPlanPreviewAction.delete,
    );

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 14 : 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: compact ? 12.5 : 14,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ShiftAutoPlanPreviewActionPill(
                  label: createLabel,
                  color: createStyle.foreground,
                  background: createStyle.badgeBackground,
                ),
                ShiftAutoPlanPreviewActionPill(
                  label: preserveLabel,
                  color: preserveStyle.foreground,
                  background: preserveStyle.badgeBackground,
                ),
                ShiftAutoPlanPreviewActionPill(
                  label: deleteLabel,
                  color: deleteStyle.foreground,
                  background: deleteStyle.badgeBackground,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
