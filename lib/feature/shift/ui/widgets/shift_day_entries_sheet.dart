import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_assignment_entity.dart';
import 'package:note_sondage/feature/shift/ui/shift_absence_status.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
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
  List<ShiftAbsenceStatus> absenceStatuses = const [],
  required bool canCreate,
  Set<String> syncingAssignmentIds = const <String>{},
  Set<String> highlightedUserIds = const <String>{},
}) {
  final dateLabel = DateFormat.yMd(
    Localizations.localeOf(context).toLanguageTag(),
  ).format(date);
  return showModalBottomSheet<ShiftDayEntriesAction>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ShiftDayEntriesSheet(
      dateLabel: dateLabel,
      assignments: assignments,
      absenceStatuses: absenceStatuses,
      canCreate: canCreate,
      syncingAssignmentIds: syncingAssignmentIds,
      highlightedUserIds: highlightedUserIds,
    ),
  );
}

class _ShiftDayEntriesSheet extends StatelessWidget {
  const _ShiftDayEntriesSheet({
    required this.dateLabel,
    required this.assignments,
    required this.absenceStatuses,
    required this.canCreate,
    required this.syncingAssignmentIds,
    required this.highlightedUserIds,
  });

  final String dateLabel;
  final List<ShiftAssignmentEntity> assignments;
  final List<ShiftAbsenceStatus> absenceStatuses;
  final bool canCreate;
  final Set<String> syncingAssignmentIds;
  final Set<String> highlightedUserIds;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dialogBackground =
        colorScheme.dialogBackgroundColor ?? colorScheme.surface;
    final borderColor = colorScheme.borderColor ?? colorScheme.outlineVariant;
    final mediaQuery = MediaQuery.of(context);
    final maxHeight = mediaQuery.size.height * 0.8;
    final assignmentUserIds = assignments
        .map((assignment) => assignment.userId.trim())
        .where((userId) => userId.isNotEmpty)
        .toSet();
    final hasHighlightedAssignments = assignments.any(
      (assignment) => highlightedUserIds.contains(assignment.userId.trim()),
    );
    final visibleAbsenceStatuses = assignmentUserIds.isEmpty
        ? absenceStatuses
        : absenceStatuses
              .where((status) => assignmentUserIds.contains(status.userId))
              .toList(growable: false);
    return SafeArea(
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
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
              loc.shiftEntriesForDate(dateLabel),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (visibleAbsenceStatuses.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: visibleAbsenceStatuses
                    .map(
                      (status) => _AbsenceStatusChip(
                        label: status.label(context),
                        color: status.color(),
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
            if (hasHighlightedAssignments) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF16A34A).withValues(alpha: 0.22),
                  ),
                ),
                child: Text(
                  _impactedBannerLabel(context),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF166534),
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: assignments
                      .map(
                        (assignment) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _AssignmentTile(
                            assignment: assignment,
                            absenceStatus: visibleAbsenceStatuses
                                .where(
                                  (status) =>
                                      status.userId == assignment.userId,
                                )
                                .firstOrNull,
                            isSyncing: syncingAssignmentIds.contains(
                              assignment.id,
                            ),
                            isHighlighted: highlightedUserIds.contains(
                              assignment.userId.trim(),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
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
                  label: Text(loc.addShift),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.bgsecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _impactedBannerLabel(BuildContext context) {
    return switch (Localizations.localeOf(context).languageCode) {
      'it' =>
        'Questi sono i turni impattati dalla tua assenza approvata per questo giorno.',
      'fr' =>
        'Voici les quarts impactes par votre absence approuvee pour cette journee.',
      'es' =>
        'Estos son los turnos afectados por tu ausencia aprobada para este dia.',
      _ =>
        'These are the shifts impacted by your approved absence for this day.',
    };
  }
}

class _AssignmentTile extends StatelessWidget {
  const _AssignmentTile({
    required this.assignment,
    this.absenceStatus,
    this.isSyncing = false,
    this.isHighlighted = false,
  });

  final ShiftAssignmentEntity assignment;
  final ShiftAbsenceStatus? absenceStatus;
  final bool isSyncing;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appPrimary = colorScheme.primaryColor ?? colorScheme.primary;
    final icon = assignment.isPublic ? Icons.public : Icons.lock_outline;
    final visibilityLabel = assignment.isPublic
        ? loc.publicProfile
        : loc.privateProfile;
    final assignee = assignment.userName?.trim().isNotEmpty == true
        ? assignment.userName!
        : assignment.userId;
    final absenceLabel = absenceStatus?.label(context);
    final highlightColor = const Color(0xFF16A34A);

    return Opacity(
      opacity: isSyncing ? 0.78 : 1,
      child: InkWell(
        onTap: () =>
            Navigator.of(context).pop(ShiftDayEntriesAction.open(assignment)),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isHighlighted
                ? highlightColor.withValues(alpha: 0.10)
                : assignment.displayColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isHighlighted
                  ? highlightColor.withValues(alpha: 0.35)
                  : assignment.displayColor.withValues(alpha: 0.35),
              width: isHighlighted ? 1.4 : 1,
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
                      assignment.profileName ?? loc.shiftReportDefaultProfile,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (isHighlighted)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: highlightColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _impactedShiftChipLabel(context),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: highlightColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    if (isSyncing)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.amber.withValues(alpha: 0.34),
                            ),
                          ),
                          child: Text(
                            loc.syncing,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.amber.shade900,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        assignee,
                        if (absenceLabel != null && absenceLabel.isNotEmpty)
                          absenceLabel,
                        '${assignment.startTime.format(context)} - ${assignment.endTime.format(context)}',
                      ].join(' • '),
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
                    color: assignment.isPublic
                        ? appPrimary
                        : colorScheme.outline,
                  ),
                  const SizedBox(height: 2),
                  Text(visibilityLabel, style: theme.textTheme.labelSmall),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _impactedShiftChipLabel(BuildContext context) {
    return switch (Localizations.localeOf(context).languageCode) {
      'it' => 'Impattato',
      'fr' => 'Impacte',
      'es' => 'Afectado',
      _ => 'Impacted',
    };
  }
}

class _AbsenceStatusChip extends StatelessWidget {
  const _AbsenceStatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
