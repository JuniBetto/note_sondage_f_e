import 'package:flutter/material.dart';
import 'package:note_sondage/feature/shift/ui/widgets/shift_calendar_team_picker.dart';
import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';

class ChatHeaderCard extends StatelessWidget {
  const ChatHeaderCard({
    super.key,
    required this.compact,
    required this.isWide,
    required this.headerDescription,
    required this.teams,
    required this.onRefreshPressed,
    required this.onTeamChanged,
    this.selectedTeamId,
  });

  final bool compact;
  final bool isWide;
  final String headerDescription;
  final List<TeamEntity> teams;
  final String? selectedTeamId;
  final VoidCallback onRefreshPressed;
  final ValueChanged<String> onTeamChanged;

  Widget _buildTeamSelector(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final pickerTeams = teams
        .where((team) => team.id != null && team.id!.isNotEmpty)
        .map(
          (team) =>
              TeamEntityForView(team: team, members: <TeamMemberforView>[]),
        )
        .toList();

    return ShiftCalendarTeamPicker(
      teams: pickerTeams,
      selectedTeamId: selectedTeamId,
      includePersonalOption: false,
      unselectedTitle: loc.selectTeam,
      triggerSubtitle: loc.changeOrSearchTeam,
      teamFallbackSubtitle: loc.teamAvailableForClocking,
      onChanged: (teamId) {
        if (teamId == null || teamId == selectedTeamId) {
          return;
        }
        onTeamChanged(teamId);
      },
    );
  }

  Widget _buildLiveChip(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFE8F8E9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 12,
          vertical: compact ? 6 : 8,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF4CAF50),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context)!.chatLive,
              style:
                  (compact
                          ? theme.textTheme.labelMedium
                          : theme.textTheme.labelLarge)
                      ?.copyWith(
                        color: const Color(0xFF235E2F),
                        fontWeight: FontWeight.w700,
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleBlock(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalizations.of(context)!.chatTeamTitle,
              style:
                  (compact
                          ? theme.textTheme.titleMedium
                          : theme.textTheme.titleLarge)
                      ?.copyWith(fontWeight: FontWeight.w800),
            ),
            FilledButton.tonalIcon(
              onPressed: onRefreshPressed,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(
                AppLocalizations.of(context)!.chatRefresh,
                style: compact ? textTheme.labelSmall : textTheme.bodySmall,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          headerDescription,
          style:
              (compact ? theme.textTheme.bodySmall : theme.textTheme.bodyMedium)
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 12 : 18),
        child: isWide
            ? Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        _buildTitleBlock(context),
                        const SizedBox(width: 16),
                        Row(
                          children: [
                            SizedBox(
                              width: 340,
                              child: _buildTeamSelector(context),
                            ),
                            const SizedBox(width: 6),
                            _buildLiveChip(context),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 16),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitleBlock(context),
                  const SizedBox(height: 12),
                  _buildLiveChip(context),
                  const SizedBox(height: 14),
                  _buildTeamSelector(context),
                ],
              ),
      ),
    );
  }
}
