import 'package:flutter/material.dart';
import 'package:note_sondage/feature/task/domain/entities/task_entity.dart';
import 'package:note_sondage/feature/task/ui/task_density_scope.dart';
import 'package:note_sondage/feature/task/ui/task_ui_support.dart';
import 'package:note_sondage/feature/task/ui/widgets/task_meta_chip.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/widgets/avatar_app.dart';

/// Desktop-oriented alternative to [TaskCard]: one row per task laid out in
/// columns, mirroring the existing team-members table look (same header/row
/// color tokens as `team_members_section.dart`) instead of introducing a new
/// visual language.
class TaskTableView extends StatelessWidget {
  const TaskTableView({
    super.key,
    required this.tasks,
    required this.selectedTaskId,
    required this.onTaskTap,
    this.assigneeAvatarUrlByUserId = const <String, String>{},
  });

  final List<TaskEntity> tasks;
  final String? selectedTaskId;
  final ValueChanged<TaskEntity> onTaskTap;
  final Map<String, String> assigneeAvatarUrlByUserId;

  @override
  Widget build(BuildContext context) {
    final scale = TaskDensityScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _TaskTableHeaderRow(),
        SizedBox(height: 6 * scale),
        Expanded(
          child: ListView.separated(
            itemCount: tasks.length,
            separatorBuilder: (_, __) => SizedBox(height: 6 * scale),
            itemBuilder: (context, index) {
              final task = tasks[index];
              return _TaskTableRow(
                key: ValueKey(task.id),
                task: task,
                selected: task.id == selectedTaskId,
                onTap: () => onTaskTap(task),
                assigneeAvatarUrl:
                    assigneeAvatarUrlByUserId[task.assigneeUserId?.trim()],
              );
            },
          ),
        ),
      ],
    );
  }
}

const _kTaskColumnFlex = <int>[4, 2, 2, 2, 3, 2];

class _TaskTableHeaderRow extends StatelessWidget {
  const _TaskTableHeaderRow();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final scale = TaskDensityScope.of(context);
    final labels = <String>[
      l10n.taskTitleLabel,
      l10n.status,
      l10n.taskPriorityLabel,
      l10n.progress,
      l10n.taskAssignedLabel,
      l10n.taskDueDateLabel,
    ];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14 * scale, vertical: 10 * scale),
      decoration: BoxDecoration(
        color: colorScheme.tableHeaderUserTeam,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              flex: _kTaskColumnFlex[i],
              child: Text(
                labels[i],
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.textInvertedColor,
                ),
              ),
            ),
          SizedBox(width: 20 * scale),
        ],
      ),
    );
  }
}

class _TaskTableRow extends StatelessWidget {
  const _TaskTableRow({
    super.key,
    required this.task,
    required this.selected,
    required this.onTap,
    this.assigneeAvatarUrl,
  });

  final TaskEntity task;
  final bool selected;
  final VoidCallback onTap;
  final String? assigneeAvatarUrl;

  String _initialsFor(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty);
    if (parts.isEmpty) {
      return '?';
    }
    return parts.map((part) => part[0].toUpperCase()).take(2).join();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final assignee = task.assigneeDisplayName?.trim();
    final scale = TaskDensityScope.of(context);

    final accent = colorScheme.primaryColor ?? colorScheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Ink(
        padding: EdgeInsets.symmetric(horizontal: 14 * scale, vertical: 10 * scale),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.08) : colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: selected
              ? Border.all(color: accent, width: 1.5)
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: _kTaskColumnFlex[0],
              child: Text(
                task.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              flex: _kTaskColumnFlex[1],
              child: Align(
                alignment: Alignment.centerLeft,
                child: TaskMetaChip(
                  label: taskStatusLabel(task.status, context),
                  color: taskStatusColor(task.status, colorScheme),
                ),
              ),
            ),
            Expanded(
              flex: _kTaskColumnFlex[2],
              child: Align(
                alignment: Alignment.centerLeft,
                child: TaskMetaChip(
                  label: taskPriorityLabel(task.priority, context),
                  color: taskPriorityColor(task.priority, colorScheme),
                ),
              ),
            ),
            Expanded(
              flex: _kTaskColumnFlex[3],
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: taskStatusProgress(task.status),
                  minHeight: (6 * scale).clamp(3, 12),
                  backgroundColor: colorScheme.voteBarBackground,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    taskStatusColor(task.status, colorScheme),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: _kTaskColumnFlex[4],
              child: assignee?.isNotEmpty == true
                  ? Row(
                      children: [
                        AvatarApp(
                          imageUrl: assigneeAvatarUrl,
                          initials: _initialsFor(assignee!),
                          size: 24 * scale,
                          backgroundColor: colorScheme.avatarBg ?? Colors.grey,
                          textColor: colorScheme.avatarTextColor ?? Colors.white,
                        ),
                        SizedBox(width: 8 * scale),
                        Expanded(
                          child: Text(
                            assignee,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      l10n.taskUnassignedOption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
            ),
            Expanded(
              flex: _kTaskColumnFlex[5],
              child: Text(
                task.dueAt == null
                    ? l10n.taskNoDueDate
                    : taskDateTimeLabel(task.dueAt!, context),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            SizedBox(
              width: 20 * scale,
              child: Icon(
                Icons.chevron_right_rounded,
                size: 18 * scale,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
