import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:note_sondage/feature/task/domain/entities/task_status.dart';
import 'package:note_sondage/feature/task/ui/task_ui_support.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';

const _kStatusOrder = <TaskStatus>[
  TaskStatus.open,
  TaskStatus.inProgress,
  TaskStatus.blocked,
  TaskStatus.done,
  TaskStatus.canceled,
];

class TaskStatusFilterBar extends StatelessWidget {
  const TaskStatusFilterBar({
    super.key,
    required this.totalCount,
    required this.countsByStatus,
    required this.selectedStatus,
    required this.showArchived,
    required this.archivedCount,
    required this.onStatusSelected,
    required this.onArchivedSelected,
  });

  final int totalCount;
  final Map<TaskStatus, int> countsByStatus;
  final TaskStatus? selectedStatus;
  final bool showArchived;
  final int archivedCount;
  final ValueChanged<TaskStatus?> onStatusSelected;
  final VoidCallback onArchivedSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: <PointerDeviceKind>{
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.trackpad,
          PointerDeviceKind.stylus,
          PointerDeviceKind.unknown,
        },
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _TaskFilterPill(
              label: l10n.taskFilterAll,
              count: totalCount,
              color: colorScheme.primaryColor ?? colorScheme.primary,
              selected: !showArchived && selectedStatus == null,
              onTap: () => onStatusSelected(null),
            ),
            for (final status in _kStatusOrder) ...[
              const SizedBox(width: 8),
              _TaskFilterPill(
                label: taskStatusLabel(status, context),
                count: countsByStatus[status] ?? 0,
                color: taskStatusColor(status, colorScheme),
                selected: !showArchived && selectedStatus == status,
                onTap: () => onStatusSelected(status),
              ),
            ],
            const SizedBox(width: 8),
            _TaskFilterPill(
              label: l10n.taskFilterArchived,
              count: archivedCount,
              color: colorScheme.onSurfaceVariant,
              selected: showArchived,
              onTap: onArchivedSelected,
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskFilterPill extends StatelessWidget {
  const _TaskFilterPill({
    required this.label,
    required this.count,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = selected ? theme.colorScheme.onPrimary : color;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? color : color.withValues(alpha: 0.24),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: selected
                    ? theme.colorScheme.onPrimary.withValues(alpha: 0.20)
                    : color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
