import 'package:flutter/material.dart';
import 'package:note_sondage/feature/task/domain/entities/task_entity.dart';
import 'package:note_sondage/feature/task/domain/entities/task_status.dart';
import 'package:note_sondage/feature/task/ui/task_ui_support.dart';
import 'package:note_sondage/feature/task/ui/widgets/task_meta_chip.dart';
import 'package:note_sondage/feature/task/ui/widgets/task_status_dropdown_field.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/widgets/app_confirmation_dialog.dart';

/// Renders the read/edit content for a single task: chips, description,
/// key dates, linked-chat banner, status control, and management actions.
///
/// Deliberately chrome-less (no card/sheet decoration) so the same content
/// can be embedded either inside a modal bottom sheet (narrow layouts) or a
/// persistent side panel (wide layouts) by the caller.
class TaskDetailPanel extends StatelessWidget {
  const TaskDetailPanel({
    super.key,
    required this.task,
    required this.canChangeStatus,
    required this.canEdit,
    required this.canRestore,
    this.canDeletePermanently = false,
    this.onStatusChange,
    this.onEdit,
    this.onArchive,
    this.onRestore,
    this.onDeletePermanently,
    this.onOpenLinkedChat,
    this.onClose,
    this.padding = const EdgeInsets.all(20),
  });

  final TaskEntity task;
  final bool canChangeStatus;
  final bool canEdit;
  final bool canRestore;
  final bool canDeletePermanently;
  final ValueChanged<TaskStatus>? onStatusChange;
  final VoidCallback? onEdit;
  final VoidCallback? onArchive;
  final VoidCallback? onRestore;
  final VoidCallback? onDeletePermanently;
  final VoidCallback? onOpenLinkedChat;
  final VoidCallback? onClose;
  final EdgeInsetsGeometry padding;

  Future<void> _confirmAndDelete(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showAppConfirmationDialog(
      context,
      title: l10n.taskDeletePermanentlyTitle,
      message: l10n.taskDeletePermanentlyMessage,
      confirmLabel: l10n.taskDeletePermanentlyAction,
      destructive: true,
    );
    if (confirmed) {
      onDeletePermanently?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isArchivedTask = task.isArchived;
    final progress = taskStatusProgress(task.status);
    final statusColor = taskStatusColor(task.status, colorScheme);
    final accent = colorScheme.primaryColor ?? colorScheme.primary;

    return ListView(
      padding: padding,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                task.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (onClose != null)
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded),
                tooltip: l10n.taskCloseAction,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            TaskMetaChip(
              label: taskStatusLabel(task.status, context),
              color: statusColor,
            ),
            TaskMetaChip(
              label: taskPriorityLabel(task.priority, context),
              color: taskPriorityColor(task.priority, colorScheme),
            ),
            if (isArchivedTask)
              TaskMetaChip(
                label: l10n.taskArchivedLabel,
                color: colorScheme.onSurfaceVariant,
              ),
          ],
        ),
        if (task.description?.trim().isNotEmpty == true) ...[
          const SizedBox(height: 16),
          Text(
            task.description!.trim(),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 18),
        _TaskDetailCard(
          rows: [
            if (task.startAt != null)
              _TaskDetailRowData(
                icon: Icons.play_circle_outline_rounded,
                label: l10n.taskStartDateLabel,
                value: taskDateTimeLabel(task.startAt!, context),
              ),
            _TaskDetailRowData(
              icon: Icons.flag_outlined,
              label: l10n.taskDueDateLabel,
              value: task.dueAt == null
                  ? l10n.taskDueDateNotSet
                  : taskDateTimeLabel(task.dueAt!, context),
            ),
            if (task.assigneeDisplayName?.trim().isNotEmpty == true)
              _TaskDetailRowData(
                icon: Icons.person_outline_rounded,
                label: l10n.taskAssignedLabel,
                value: task.assigneeDisplayName!.trim(),
              ),
            _TaskDetailRowData(
              icon: Icons.edit_note_rounded,
              label: l10n.taskCreatedByLabel,
              value: task.createdByDisplayName?.trim().isNotEmpty == true
                  ? task.createdByDisplayName!.trim()
                  : task.createdByUserId,
            ),
            _TaskDetailRowData(
              icon: Icons.history_rounded,
              label: l10n.taskUpdatedLabel,
              value: taskDateTimeLabel(task.updatedAt, context),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          l10n.progress,
          style: theme.textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: colorScheme.voteBarBackground,
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '${(progress * 100).round()}%',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: statusColor,
              ),
            ),
          ],
        ),
        if (task.workflowMetadata?.sourceMessageId?.trim().isNotEmpty == true)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: accent.withValues(alpha: 0.2)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.taskSourceChatMessage,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (task.workflowMetadata?.contextId?.trim().isNotEmpty ==
                        true)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: OutlinedButton.icon(
                          onPressed: onOpenLinkedChat,
                          icon: const Icon(Icons.chat_bubble_outline_rounded),
                          label: Text(l10n.taskOpenLinkedConversation),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 18),
        if (canChangeStatus && onStatusChange != null)
          TaskStatusDropdownField(
            label: l10n.taskUpdateStatusLabel,
            status: task.status,
            options: allowedTaskStatuses(task, canManageTask: canEdit),
            onChanged: (nextStatus) {
              if (nextStatus == task.status) {
                return;
              }
              onStatusChange!(nextStatus);
            },
          ),
        const SizedBox(height: 18),
        if (canEdit && onEdit != null)
          FilledButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
            label: Text(l10n.taskEditAction),
          ),
        if (canEdit && onArchive != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: OutlinedButton.icon(
              onPressed: onArchive,
              icon: const Icon(Icons.archive_outlined),
              label: Text(l10n.taskArchiveAction),
            ),
          ),
        if (canRestore && onRestore != null)
          FilledButton.icon(
            onPressed: onRestore,
            icon: const Icon(Icons.unarchive_outlined),
            label: Text(l10n.taskRestoreAction),
          ),
        if (canDeletePermanently && onDeletePermanently != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: OutlinedButton.icon(
              onPressed: () => _confirmAndDelete(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.error,
                side: BorderSide(color: colorScheme.error),
              ),
              icon: const Icon(Icons.delete_forever_outlined),
              label: Text(l10n.taskDeletePermanentlyAction),
            ),
          ),
      ],
    );
  }
}

class _TaskDetailRowData {
  const _TaskDetailRowData({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class _TaskDetailCard extends StatelessWidget {
  const _TaskDetailCard({required this.rows});

  final List<_TaskDetailRowData> rows;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.borderColor ?? colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: (colorScheme.borderColor ?? colorScheme.outlineVariant)
                    .withValues(alpha: 0.6),
              ),
            _TaskDetailRow(data: rows[i]),
          ],
        ],
      ),
    );
  }
}

class _TaskDetailRow extends StatelessWidget {
  const _TaskDetailRow({required this.data});

  final _TaskDetailRowData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = colorScheme.primaryColor ?? colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(data.icon, size: 18, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
