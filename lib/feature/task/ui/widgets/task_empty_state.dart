import 'package:flutter/material.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';

class TaskEmptyState extends StatelessWidget {
  const TaskEmptyState({
    super.key,
    required this.canManageSelectedTeam,
    this.isArchivedView = false,
  });

  final bool canManageSelectedTeam;
  final bool isArchivedView;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: colorScheme.borderColor ?? colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isArchivedView
                    ? Icons.inventory_2_outlined
                    : Icons.task_alt_rounded,
                color: colorScheme.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              isArchivedView
                  ? l10n.taskEmptyArchivedTitle
                  : l10n.taskEmptyActiveTitle,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isArchivedView
                  ? l10n.taskEmptyArchivedSubtitle
                  : (canManageSelectedTeam
                        ? l10n.taskEmptyActiveSubtitleManage
                        : l10n.taskEmptyActiveSubtitleReadOnly),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
