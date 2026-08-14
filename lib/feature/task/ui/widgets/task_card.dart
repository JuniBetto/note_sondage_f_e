import 'package:flutter/material.dart';
import 'package:note_sondage/feature/task/domain/entities/task_entity.dart';
import 'package:note_sondage/feature/task/ui/task_ui_support.dart';
import 'package:note_sondage/feature/task/ui/widgets/task_meta_chip.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.locale,
    required this.onTap,
  });

  final TaskEntity task;
  final String locale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: colorScheme.borderColor ?? colorScheme.outlineVariant,
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.05),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        if (task.description?.trim().isNotEmpty == true) ...[
                          const SizedBox(height: 6),
                          Text(
                            task.description!.trim(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  TaskMetaChip(
                    label: taskStatusLabel(task.status, locale),
                    color: taskStatusColor(task.status),
                  ),
                  TaskMetaChip(
                    label: taskPriorityLabel(task.priority, locale),
                    color: taskPriorityColor(task.priority),
                  ),
                  if (task.assigneeDisplayName?.trim().isNotEmpty == true)
                    TaskMetaChip(
                      label: task.assigneeDisplayName!.trim(),
                      color: colorScheme.primary,
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _TaskInfoLine(
                      icon: Icons.schedule_rounded,
                      value: task.dueAt == null
                          ? taskText(
                              locale,
                              it: 'Senza scadenza',
                              en: 'No due date',
                            )
                          : taskDateTimeLabel(task.dueAt!, context),
                    ),
                  ),
                  if (task.createdByDisplayName?.trim().isNotEmpty == true)
                    Expanded(
                      child: _TaskInfoLine(
                        icon: Icons.person_outline_rounded,
                        value: task.createdByDisplayName!.trim(),
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

class _TaskInfoLine extends StatelessWidget {
  const _TaskInfoLine({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
