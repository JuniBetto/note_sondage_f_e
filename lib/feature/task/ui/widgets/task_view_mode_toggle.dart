import 'package:flutter/material.dart';
import 'package:note_sondage/feature/task/ui/widgets/task_view_mode_button.dart';

import '../../../../languages/l10n/app_localizations.dart';
import '../../../../theme/extensions/color_scheme/color_scheme.dart';
import '../task_workspace.dart';

class TaskViewModeToggle extends StatelessWidget {
  const TaskViewModeToggle({
    super.key,
    required this.viewMode,
    required this.onChanged,
  });

  final TaskViewMode viewMode;
  final ValueChanged<TaskViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final borderColor = colorScheme.borderColor ?? colorScheme.outlineVariant;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TaskViewModeButton(
              icon: Icons.view_agenda_rounded,
              tooltip: l10n.taskViewModeList,
              selected: viewMode == TaskViewMode.list,
              onTap: () => onChanged(TaskViewMode.list),
            ),
            TaskViewModeButton(
              icon: Icons.table_rows_rounded,
              tooltip: l10n.taskViewModeTable,
              selected: viewMode == TaskViewMode.table,
              onTap: () => onChanged(TaskViewMode.table),
            ),
            TaskViewModeButton(
              icon: Icons.view_timeline_rounded,
              tooltip: l10n.taskViewModeTimeline,
              selected: viewMode == TaskViewMode.timeline,
              onTap: () => onChanged(TaskViewMode.timeline),
            ),
            TaskViewModeButton(
              icon: Icons.calendar_month_rounded,
              tooltip: l10n.taskViewModeCalendar,
              selected: viewMode == TaskViewMode.calendar,
              onTap: () => onChanged(TaskViewMode.calendar),
            ),
          ],
        ),
      ),
    );
  }
}
