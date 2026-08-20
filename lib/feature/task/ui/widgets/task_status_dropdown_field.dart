import 'package:flutter/material.dart';
import 'package:note_sondage/feature/task/domain/entities/task_status.dart';
import 'package:note_sondage/feature/task/ui/task_ui_support.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/widgets/anchored_dropdown_overlay.dart';

/// Status picker for [TaskDetailPanel], styled like the app's other
/// anchored select dropdowns (e.g. [ShiftCalendarTeamPicker]) instead of a
/// bare Material [DropdownButtonFormField].
class TaskStatusDropdownField extends StatelessWidget {
  const TaskStatusDropdownField({
    super.key,
    required this.label,
    required this.status,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final TaskStatus status;
  final List<TaskStatus> options;
  final ValueChanged<TaskStatus> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnchoredDropdownOverlay(
      triggerBuilder: (context, isOpen, toggle) => _StatusTriggerCard(
        label: label,
        status: status,
        isOpen: isOpen,
        onTap: toggle,
      ),
      overlayBuilder: (context, width, maxHeight, close) => Container(
        width: width,
        constraints: BoxConstraints(maxHeight: maxHeight),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Scrollbar(
          thumbVisibility: options.length > 3,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < options.length; i++) ...[
                  if (i > 0) const SizedBox(height: 6),
                  _StatusOptionTile(
                    status: options[i],
                    isSelected: options[i] == status,
                    onTap: () {
                      onChanged(options[i]);
                      close();
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusTriggerCard extends StatelessWidget {
  const _StatusTriggerCard({
    required this.label,
    required this.status,
    required this.isOpen,
    required this.onTap,
  });

  final String label;
  final TaskStatus status;
  final bool isOpen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = colorScheme.primaryColor ?? colorScheme.primary;
    final statusColor = taskStatusColor(status, colorScheme);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isOpen
                ? accent.withValues(alpha: 0.45)
                : colorScheme.outlineVariant,
          ),
          color: isOpen ? accent.withValues(alpha: 0.05) : colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isOpen ? 0.05 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.descriptionColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    taskStatusLabel(status, context),
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              isOpen
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              size: 20,
              color: colorScheme.descriptionColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusOptionTile extends StatelessWidget {
  const _StatusOptionTile({
    required this.status,
    required this.isSelected,
    required this.onTap,
  });

  final TaskStatus status;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = colorScheme.primaryColor ?? colorScheme.primary;
    final statusColor = taskStatusColor(status, colorScheme);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? accent.withValues(alpha: 0.45)
                : colorScheme.outlineVariant,
          ),
          color: isSelected
              ? accent.withValues(alpha: 0.08)
              : colorScheme.surface,
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                taskStatusLabel(status, context),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, size: 18, color: accent),
          ],
        ),
      ),
    );
  }
}
