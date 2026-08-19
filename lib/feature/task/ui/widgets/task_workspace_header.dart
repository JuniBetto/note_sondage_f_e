import 'package:flutter/material.dart';
import 'package:note_sondage/feature/shift/ui/widgets/shift_calendar_team_picker.dart';
import 'package:note_sondage/feature/task/ui/widgets/task_text_size_toggle.dart';
import 'package:note_sondage/feature/task/ui/widgets/task_view_mode_toggle.dart';
import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/widgets/app_search_field.dart';

import '../task_workspace.dart';

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
    required this.viewMode,
    required this.onViewModeChanged,
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
  final TaskViewMode viewMode;
  final ValueChanged<TaskViewMode> onViewModeChanged;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;

  Widget _buildTeamPicker(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pickerTeams = teams
        .where((team) => team.id != null && team.id!.isNotEmpty)
        .map(
          (team) =>
              TeamEntityForView(team: team, members: <TeamMemberforView>[]),
        )
        .toList(growable: false);

    return ShiftCalendarTeamPicker(
      teams: pickerTeams,
      selectedTeamId: selectedTeamId,
      includePersonalOption: true,
      personalOptionTitle: l10n.taskMyTasksTitle,
      personalOptionSubtitle: l10n.taskMyTasksSubtitle,
      triggerSubtitle: l10n.changeOrSearchTeam,
      teamFallbackSubtitle: l10n.teamAvailableForClocking,
      onChanged: onTeamChanged,
    );
  }

  Widget _buildNewTaskButton(BuildContext context, {bool short = false}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final navButtonColor =
        colorScheme.bgNavbarbutton ?? colorScheme.primaryColor ?? colorScheme.primary;
    final onNavButtonColor = colorScheme.textInvertedColor ?? Colors.white;

    return FilledButton.icon(
      onPressed: canManageSelectedTeam ? onCreateTask : null,
      style: FilledButton.styleFrom(backgroundColor: navButtonColor),
      icon: Icon(Icons.add_task_rounded, color: onNavButtonColor),
      label: Text(
        short ? l10n.taskNewTaskActionShort : l10n.taskNewTaskAction,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: onNavButtonColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildBanner(BuildContext context, {required bool isCompact}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final accent = colorScheme.primaryColor ?? colorScheme.primary;

    final iconChip = Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.checklist_rounded, color: accent, size: 24),
    );

    final textBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.taskHeaderTitle,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: colorScheme.iconLabel,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          l10n.taskHeaderSubtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: colorScheme.bgNavbarSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: isCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    iconChip,
                    const SizedBox(width: 14),
                    Expanded(child: textBlock),
                  ],
                ),
                const SizedBox(height: 14),
                _buildNewTaskButton(context),
              ],
            )
          : Row(
              children: [
                iconChip,
                const SizedBox(width: 14),
                Expanded(child: textBlock),
                const SizedBox(width: 16),
                _buildNewTaskButton(context),
              ],
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 760;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!embedded) ...[
              _buildBanner(context, isCompact: isCompact),
              const SizedBox(height: 16),
            ],
            if (isCompact)
              Column(
                children: [
                  _buildTeamPicker(context),
                  const SizedBox(height: 12),
                  AppSearchField(
                    controller: searchController,
                    hintText: l10n.taskSearchHint,
                    onChanged: onSearchChanged,
                  ),
                  const SizedBox(height: 12),
                  if (embedded)
                    Row(
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: _buildNewTaskButton(context),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Wrap(
                            alignment: WrapAlignment.end,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              const TaskTextSizeToggle(),
                              TaskViewModeToggle(
                                viewMode: viewMode,
                                onChanged: onViewModeChanged,
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  else
                    Wrap(
                      alignment: WrapAlignment.end,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        const TaskTextSizeToggle(),
                        TaskViewModeToggle(
                          viewMode: viewMode,
                          onChanged: onViewModeChanged,
                        ),
                      ],
                    ),
                ],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: _buildTeamPicker(context)),
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
                    _buildNewTaskButton(context, short: true),
                  ],
                  const SizedBox(width: 12),
                  TaskViewModeToggle(
                    viewMode: viewMode,
                    onChanged: onViewModeChanged,
                  ),
                ],
              ),
            if (loadingAccess)
              const Padding(
                padding: EdgeInsets.only(top: 14),
                child: LinearProgressIndicator(minHeight: 2),
              ),
          ],
        );
      },
    );
  }
}
