import 'package:flutter/material.dart';
import 'package:note_sondage/feature/task/ui/task_ui_support.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';

class TaskEmptyState extends StatelessWidget {
  const TaskEmptyState({
    super.key,
    required this.locale,
    required this.canManageSelectedTeam,
  });

  final String locale;
  final bool canManageSelectedTeam;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
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
                Icons.task_alt_rounded,
                color: colorScheme.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              taskText(locale, it: 'Nessun task attivo', en: 'No active tasks'),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              taskText(
                locale,
                it: canManageSelectedTeam
                    ? 'Per questo team non ci sono task attivi. Puoi crearne uno da qui o dalla chat.'
                    : 'Per questo team non ci sono task attivi al momento.',
                en: canManageSelectedTeam
                    ? 'There are no active tasks for this team yet. You can create one here or from chat.'
                    : 'There are no active tasks for this team right now.',
              ),
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
