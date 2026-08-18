import 'package:flutter/material.dart';
import 'package:note_sondage/feature/task/ui/widgets/task_summary_chip.dart';
import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/widgets/app_search_field.dart';

class TaskWorkspaceHeader extends StatelessWidget {
  const TaskWorkspaceHeader({
    super.key,
    required this.embedded,
    required this.teams,
    required this.selectedTeamId,
    required this.onTeamChanged,
    required this.canManageSelectedTeam,
    required this.onCreateTask,
    required this.loadingAccess,
    required this.totalTasks,
    required this.openTasks,
    required this.inProgressTasks,
    required this.doneTasks,
    required this.searchController,
    required this.onSearchChanged,
  });

  final bool embedded;
  final List<TeamEntity> teams;
  final String? selectedTeamId;
  final ValueChanged<String?> onTeamChanged;
  final bool canManageSelectedTeam;
  final VoidCallback onCreateTask;
  final bool loadingAccess;
  final int totalTasks;
  final int openTasks;
  final int inProgressTasks;
  final int doneTasks;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final borderColor = colorScheme.borderColor ?? colorScheme.outlineVariant;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 760;
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primary.withValues(alpha: 0.10),
                colorScheme.surface,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.05),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!embedded) ...[
                  if (isCompact)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _HeaderTextBlock(),
                        const SizedBox(height: 14),
                        FilledButton.icon(
                          onPressed: canManageSelectedTeam
                              ? onCreateTask
                              : null,
                          icon: const Icon(Icons.add_task_rounded),
                          label: Text(l10n.taskNewTaskAction),
                        ),
                      ],
                    )
                  else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Expanded(child: _HeaderTextBlock()),
                        const SizedBox(width: 16),
                        FilledButton.icon(
                          onPressed: canManageSelectedTeam
                              ? onCreateTask
                              : null,
                          icon: const Icon(Icons.add_task_rounded),
                          label: Text(l10n.taskNewTaskAction),
                        ),
                      ],
                    ),
                  const SizedBox(height: 18),
                ],
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    TaskSummaryChip(
                      label: l10n.taskSummaryTotal,
                      value: totalTasks,
                      color: colorScheme.primary,
                    ),
                    TaskSummaryChip(
                      label: l10n.taskSummaryOpen,
                      value: openTasks,
                      color: colorScheme.infoColor,
                    ),
                    TaskSummaryChip(
                      label: l10n.taskStatusInProgress,
                      value: inProgressTasks,
                      color: colorScheme.warningColor,
                    ),
                    TaskSummaryChip(
                      label: l10n.taskSummaryDone,
                      value: doneTasks,
                      color: colorScheme.successColor,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (isCompact)
                  Column(
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: selectedTeamId,
                        decoration: InputDecoration(
                          labelText: l10n.taskTeamLabel,
                        ),
                        items: teams
                            .map(
                              (team) => DropdownMenuItem<String>(
                                value: team.id!.trim(),
                                child: Text(team.name),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: onTeamChanged,
                      ),
                      const SizedBox(height: 12),
                      AppSearchField(
                        controller: searchController,
                        hintText: l10n.taskSearchHint,
                        onChanged: onSearchChanged,
                      ),
                      if (embedded) ...[
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: FilledButton.icon(
                            onPressed: canManageSelectedTeam
                                ? onCreateTask
                                : null,
                            icon: const Icon(Icons.add_task_rounded),
                            label: Text(l10n.taskNewTaskAction),
                          ),
                        ),
                      ],
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedTeamId,
                          decoration: InputDecoration(
                            labelText: l10n.taskTeamLabel,
                          ),
                          items: teams
                              .map(
                                (team) => DropdownMenuItem<String>(
                                  value: team.id!.trim(),
                                  child: Text(team.name),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: onTeamChanged,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 4,
                        child: AppSearchField(
                          controller: searchController,
                          hintText: l10n.taskSearchHint,
                          onChanged: onSearchChanged,
                        ),
                      ),
                      if (embedded) ...[
                        const SizedBox(width: 12),
                        FilledButton.icon(
                          onPressed: canManageSelectedTeam
                              ? onCreateTask
                              : null,
                          icon: const Icon(Icons.add_task_rounded),
                          label: Text(l10n.taskNewTaskActionShort),
                        ),
                      ],
                    ],
                  ),
                if (loadingAccess)
                  const Padding(
                    padding: EdgeInsets.only(top: 14),
                    child: LinearProgressIndicator(minHeight: 2),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HeaderTextBlock extends StatelessWidget {
  const _HeaderTextBlock();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.taskHeaderTitle,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.taskHeaderSubtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
