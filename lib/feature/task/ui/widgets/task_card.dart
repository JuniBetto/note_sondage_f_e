import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:note_sondage/feature/task/domain/entities/task_entity.dart';
import 'package:note_sondage/feature/task/ui/task_density_scope.dart';
import 'package:note_sondage/feature/task/ui/task_ui_support.dart';
import 'package:note_sondage/feature/task/ui/widgets/task_meta_chip.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/widgets/avatar_app.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    this.selected = false,
    this.assigneeAvatarUrl,
  });

  final TaskEntity task;
  final VoidCallback onTap;
  final bool selected;
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
    final theme = Theme.of(context);
    final statusColor = taskStatusColor(task.status, colorScheme);
    final accent = colorScheme.primaryColor ?? colorScheme.primary;
    final assignee = task.assigneeDisplayName?.trim();
    final dueAt = task.dueAt;
    final scale = TaskDensityScope.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.06) : colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? accent
                : (colorScheme.borderColor ?? colorScheme.outlineVariant),
            width: selected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(16 * scale),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (dueAt != null) ...[
                    SizedBox(width: 10 * scale),
                    _DatePill(date: dueAt),
                  ],
                ],
              ),
              if (task.description?.trim().isNotEmpty == true) ...[
                SizedBox(height: 4 * scale),
                Text(
                  task.description!.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              SizedBox(height: 12 * scale),
              Wrap(
                spacing: 8 * scale,
                runSpacing: 8 * scale,
                children: [
                  TaskMetaChip(
                    label: taskStatusLabel(task.status, context),
                    color: statusColor,
                  ),
                  TaskMetaChip(
                    label: taskPriorityLabel(task.priority, context),
                    color: taskPriorityColor(task.priority, colorScheme),
                  ),
                ],
              ),
              SizedBox(height: 14 * scale),
              Row(
                children: [
                  AvatarApp(
                    imageUrl: assigneeAvatarUrl,
                    initials: assignee?.isNotEmpty == true
                        ? _initialsFor(assignee!)
                        : '?',
                    size: 26 * scale,
                    backgroundColor: assignee?.isNotEmpty == true
                        ? (colorScheme.avatarBg ?? Colors.grey)
                        : (colorScheme.avatarBg ?? Colors.grey).withValues(
                            alpha: 0.5,
                          ),
                    textColor: colorScheme.avatarTextColor ?? Colors.white,
                  ),
                  SizedBox(width: 10 * scale),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: taskStatusProgress(task.status),
                        minHeight: (6 * scale).clamp(3, 12),
                        backgroundColor: colorScheme.voteBarBackground,
                        valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DatePill extends StatelessWidget {
  const _DatePill({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = colorScheme.primaryColor ?? colorScheme.primary;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final scale = TaskDensityScope.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8 * scale, vertical: 4 * scale),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        DateFormat.MMMd(locale).format(date),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: accent,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
