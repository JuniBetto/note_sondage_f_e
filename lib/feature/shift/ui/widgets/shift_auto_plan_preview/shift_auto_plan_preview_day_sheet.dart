import 'package:flutter/material.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_auto_plan_entity.dart';

import 'shift_auto_plan_preview_action_support.dart';

class ShiftAutoPlanPreviewDaySheetItem {
  const ShiftAutoPlanPreviewDaySheetItem({
    required this.title,
    required this.subtitle,
    required this.action,
    this.onEdit,
    this.onRemove,
    this.onRestore,
    this.editLabel,
    this.removeLabel,
    this.restoreLabel,
  });

  final String title;
  final String subtitle;
  final ShiftAutoPlanPreviewAction action;
  final VoidCallback? onEdit;
  final VoidCallback? onRemove;
  final VoidCallback? onRestore;
  final String? editLabel;
  final String? removeLabel;
  final String? restoreLabel;
}

Future<void> showShiftAutoPlanPreviewDaySheet(
  BuildContext context, {
  required bool compact,
  required String title,
  required String description,
  required List<ShiftAutoPlanPreviewDaySheetItem> items,
  required String Function(ShiftAutoPlanPreviewAction action)
  actionLabelBuilder,
  String? primaryActionLabel,
  VoidCallback? onPrimaryAction,
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
                if (onPrimaryAction != null && primaryActionLabel != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonal(
                      onPressed: onPrimaryAction,
                      child: Text(primaryActionLabel),
                    ),
                  ),
                ],
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
                if (item.onEdit != null ||
                    item.onRemove != null ||
                    item.onRestore != null) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (item.onEdit != null)
                        OutlinedButton(
                          onPressed: item.onEdit,
                          child: Text(item.editLabel ?? 'Edit'),
                        ),
                      if (item.onRemove != null)
                        OutlinedButton(
                          onPressed: item.onRemove,
                          child: Text(item.removeLabel ?? 'Remove'),
                        ),
                      if (item.onRestore != null)
                        FilledButton.tonal(
                          onPressed: item.onRestore,
                          child: Text(item.restoreLabel ?? 'Restore'),
                        ),
                    ],
                  ),
                ],
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
