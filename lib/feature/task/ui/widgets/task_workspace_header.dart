import 'package:flutter/material.dart';
import 'package:note_sondage/feature/task/ui/task_ui_support.dart';
import 'package:note_sondage/feature/task/ui/widgets/task_summary_chip.dart';
import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/widgets/app_search_field.dart';

class TaskWorkspaceHeader extends StatelessWidget {
  const TaskWorkspaceHeader({
    super.key,
    required this.locale,
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

  final String locale;
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
                        _HeaderTextBlock(locale: locale),
                        const SizedBox(height: 14),
                        FilledButton.icon(
                          onPressed: canManageSelectedTeam
                              ? onCreateTask
                              : null,
                          icon: const Icon(Icons.add_task_rounded),
                          label: Text(
                            taskText(locale, it: 'Nuovo task', en: 'New task'),
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _HeaderTextBlock(locale: locale)),
                        const SizedBox(width: 16),
                        FilledButton.icon(
                          onPressed: canManageSelectedTeam
                              ? onCreateTask
                              : null,
                          icon: const Icon(Icons.add_task_rounded),
                          label: Text(
                            taskText(locale, it: 'Nuovo task', en: 'New task'),
                          ),
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
                      label: taskText(locale, it: 'Totali', en: 'Total'),
                      value: totalTasks,
                      color: colorScheme.primary,
                    ),
                    TaskSummaryChip(
                      label: taskText(locale, it: 'Aperti', en: 'Open'),
                      value: openTasks,
                      color: Colors.blue,
                    ),
                    TaskSummaryChip(
                      label: taskText(
                        locale,
                        it: 'In corso',
                        en: 'In progress',
                      ),
                      value: inProgressTasks,
                      color: Colors.orange,
                    ),
                    TaskSummaryChip(
                      label: taskText(locale, it: 'Completati', en: 'Done'),
                      value: doneTasks,
                      color: Colors.green,
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
                          labelText: taskText(locale, it: 'Team', en: 'Team'),
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
                        hintText: taskText(
                          locale,
                          it: 'Cerca per titolo, descrizione o assegnatario',
                          en: 'Search by title, description, or assignee',
                        ),
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
                            label: Text(
                              taskText(
                                locale,
                                it: 'Nuovo task',
                                en: 'New task',
                              ),
                            ),
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
                            labelText: taskText(locale, it: 'Team', en: 'Team'),
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
                          hintText: taskText(
                            locale,
                            it: 'Cerca per titolo, descrizione o assegnatario',
                            en: 'Search by title, description, or assignee',
                          ),
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
                          label: Text(taskText(locale, it: 'Nuovo', en: 'New')),
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
  const _HeaderTextBlock({required this.locale});

  final String locale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          taskText(
            locale,
            it: 'Task operativi del team',
            en: 'Team operational tasks',
          ),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          taskText(
            locale,
            it: 'Organizza attivita operative, follow-up e azioni nate da chat, turni o esigenze del team.',
            en: 'Organize operational work, follow-ups, and actions coming from chat, shifts, or team needs.',
          ),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
