import 'package:flutter/material.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_assignment_entity.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';

enum ShiftDayEntriesActionType { createNew, openExisting }

class ShiftDayEntriesAction {
  const ShiftDayEntriesAction.create()
    : type = ShiftDayEntriesActionType.createNew,
      assignment = null;

  const ShiftDayEntriesAction.open(this.assignment)
    : type = ShiftDayEntriesActionType.openExisting;

  final ShiftDayEntriesActionType type;
  final ShiftAssignmentEntity? assignment;
}

Future<ShiftDayEntriesAction?> showShiftDayEntriesSheet({
  required BuildContext context,
  required DateTime date,
  required List<ShiftAssignmentEntity> assignments,
  required bool canCreate,
}) {
  final dateLabel = '${date.day}/${date.month}/${date.year}';
  return showModalBottomSheet<ShiftDayEntriesAction>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => _ShiftDayEntriesSheet(
      dateLabel: dateLabel,
      assignments: assignments,
      canCreate: canCreate,
    ),
  );
}

class _ShiftDayEntriesSheet extends StatelessWidget {
  const _ShiftDayEntriesSheet({
    required this.dateLabel,
    required this.assignments,
    required this.canCreate,
  });

  final String dateLabel;
  final List<ShiftAssignmentEntity> assignments;
  final bool canCreate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dialogBackground =
        colorScheme.dialogBackgroundColor ?? colorScheme.surface;
    final borderColor =
        colorScheme.borderColor ?? colorScheme.outlineVariant;
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: dialogBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor.withValues(alpha: 0.7)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Turni del $dateLabel',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ...assignments.map(
            (assignment) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _AssignmentTile(assignment: assignment),
            ),
          ),
          if (canCreate) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.of(
                  context,
                ).pop(const ShiftDayEntriesAction.create()),
                icon: const Icon(Icons.add),
                label: const Text('Nuovo turno'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AssignmentTile extends StatelessWidget {
  const _AssignmentTile({required this.assignment});

  final ShiftAssignmentEntity assignment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appPrimary = colorScheme.primaryColor ?? colorScheme.primary;
    final icon = assignment.isPublic ? Icons.public : Icons.lock_outline;
    final visibilityLabel = assignment.isPublic ? 'Pubblico' : 'Privato';
    final assignee = assignment.userName?.trim().isNotEmpty == true
        ? assignment.userName!
        : assignment.userId;

    return InkWell(
      onTap: () => Navigator.of(context).pop(ShiftDayEntriesAction.open(assignment)),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: assignment.displayColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: assignment.displayColor.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: assignment.displayColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    assignment.profileName ?? 'Turno',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$assignee • ${assignment.startTime.format(context)} - ${assignment.endTime.format(context)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: assignment.isPublic ? appPrimary : colorScheme.outline,
                ),
                const SizedBox(height: 2),
                Text(visibilityLabel, style: theme.textTheme.labelSmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
