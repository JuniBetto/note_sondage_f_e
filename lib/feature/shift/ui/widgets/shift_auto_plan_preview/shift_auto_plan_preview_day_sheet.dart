import 'package:flutter/material.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_auto_plan_entity.dart';

import 'shift_auto_plan_preview_action_support.dart';

class ShiftAutoPlanPreviewDaySheetItem {
  const ShiftAutoPlanPreviewDaySheetItem({
    required this.title,
    required this.subtitle,
    required this.action,
  });

  final String title;
  final String subtitle;
  final ShiftAutoPlanPreviewAction action;
}

Future<void> showShiftAutoPlanPreviewDaySheet(
  BuildContext context, {
  required bool compact,
  required String title,
  required String description,
  required List<ShiftAutoPlanPreviewDaySheetItem> items,
  required String Function(ShiftAutoPlanPreviewAction action)
  actionLabelBuilder,
}) {
  final theme = Theme.of(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            compact ? 12 : 20,
            8,
            compact ? 12 : 20,
            compact ? 12 : 20,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetContext).size.height * 0.72,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: items
                        .map(
                          (item) => _PreviewItem(
                            compact: compact,
                            item: item,
                            actionLabel: actionLabelBuilder(item.action),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _PreviewItem extends StatelessWidget {
  const _PreviewItem({
    required this.compact,
    required this.item,
    required this.actionLabel,
  });

  final bool compact;
  final ShiftAutoPlanPreviewDaySheetItem item;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actionStyle = shiftAutoPlanPreviewActionStyle(item.action);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: BoxDecoration(
        color: actionStyle.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: actionStyle.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: compact ? 12.5 : 13.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ShiftAutoPlanPreviewActionPill(
            label: actionLabel,
            color: actionStyle.foreground,
            background: actionStyle.badgeBackground,
          ),
        ],
      ),
    );
  }
}
