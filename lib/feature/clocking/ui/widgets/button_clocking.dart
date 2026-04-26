import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_sondage/feature/clocking/domain/entities/clocking_record_entity.dart';
import 'package:note_sondage/feature/clocking/ui/bloc/clocking_bloc.dart';
import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';
import 'package:note_sondage/feature/team/ui/bloc/team/team_bloc.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';

class ButtonClocking extends StatefulWidget {
  const ButtonClocking({super.key, this.isCompact = false});
  final bool isCompact;

  @override
  State<ButtonClocking> createState() => _ButtonClockingState();
}

class _ButtonClockingState extends State<ButtonClocking> {
  String? _selectedTeamId;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;

    return BlocListener<ClockingBloc, ClockingState>(
      listenWhen: (previous, current) => current is ClockingError,
      listener: (context, state) {
        if (state is! ClockingError) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.redAccent,
            ),
          );
      },
      child: BlocBuilder<TeamBloc, TeamState>(
        builder: (context, teamState) {
          final teams = teamState is TeamsLoaded ? teamState.teams : <TeamEntity>[];
          _ensureSelectedTeam(teams);

          return BlocBuilder<ClockingBloc, ClockingState>(
            builder: (context, clockingState) {
              final records = _extractRecords(clockingState);
              final activeRecord = _selectedTeamActiveRecord(records);
              final hasTeams = teams.isNotEmpty;

              final clockColor = activeRecord != null ? Colors.red : Colors.green;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ClockingTeamSelector(
                    isCompact: widget.isCompact,
                    teams: teams,
                    selectedTeamId: _selectedTeamId,
                    onChanged: (value) {
                      setState(() => _selectedTeamId = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ClockActionButton(
                        onTap: hasTeams ? () => _onClockAction(activeRecord) : null,
                        color: clockColor,
                        icon: activeRecord != null
                            ? Icons.stop_rounded
                            : Icons.play_arrow_rounded,
                        label: activeRecord != null
                            ? localization.clockedOutAt.replaceAll(':', '').trim()
                            : localization.clockedInAt.replaceAll(':', '').trim(),
                        subtitle: activeRecord != null
                            ? 'Chiudi il turno del team selezionato'
                            : 'Apri il turno del team selezionato',
                        isCompact: widget.isCompact,
                        isDisabled: !hasTeams,
                      ),
                      const SizedBox(width: 12),
                      _ClockActionButton(
                        onTap: null,
                        color: Colors.grey[500]!,
                        icon: Icons.coffee_rounded,
                        label: localization.startBreakAt.replaceAll(':', '').trim(),
                        subtitle: 'Break non ancora collegato al backend',
                        isCompact: widget.isCompact,
                        isDisabled: true,
                      ),
                    ],
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _ensureSelectedTeam(List<TeamEntity> teams) {
    if (teams.isEmpty) {
      _selectedTeamId = null;
      return;
    }

    final teamIds = teams.map((team) => team.id).whereType<String>().toSet();
    if (_selectedTeamId == null || !teamIds.contains(_selectedTeamId)) {
      for (final team in teams) {
        if (team.id != null) {
          _selectedTeamId = team.id;
          break;
        }
      }
    }
  }

  List<ClockingRecordEntity> _extractRecords(ClockingState state) {
    if (state is ClockingRecordsLoaded) return state.records;
    return const [];
  }

  ClockingRecordEntity? _selectedTeamActiveRecord(
    List<ClockingRecordEntity> records,
  ) {
    final selectedTeamId = _selectedTeamId;
    if (selectedTeamId == null) return null;

    for (final record in records) {
      if (record.teamId == selectedTeamId &&
          record.status == ClockingStatus.clockedIn &&
          record.clockOutTime == null) {
        return record;
      }
    }
    return null;
  }

  void _onClockAction(ClockingRecordEntity? activeRecord) {
    final selectedTeamId = _selectedTeamId;
    if (selectedTeamId == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Seleziona prima un team per timbrare.'),
            backgroundColor: Colors.orange,
          ),
        );
      return;
    }

    if (activeRecord == null) {
      context.read<ClockingBloc>().add(ClockInEvent(teamId: selectedTeamId));
      return;
    }

    context.read<ClockingBloc>().add(ClockOutEvent(teamId: selectedTeamId));
  }
}

class _ClockingTeamSelector extends StatelessWidget {
  const _ClockingTeamSelector({
    required this.isCompact,
    required this.teams,
    required this.selectedTeamId,
    required this.onChanged,
  });

  final bool isCompact;
  final List<TeamEntity> teams;
  final String? selectedTeamId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: BoxConstraints(maxWidth: isCompact ? 320 : 380),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.bgNavbarSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: DropdownButtonFormField<String>(
        value: teams.any((team) => team.id == selectedTeamId) ? selectedTeamId : null,
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          labelText: 'Team',
        ),
        items: teams
            .where((team) => team.id != null)
            .map(
              (team) {
                final teamId = team.id!;
                return DropdownMenuItem<String>(
                value: teamId,
                child: Text(team.name),
              );
              },
            )
            .toList(),
        onChanged: teams.isEmpty ? null : onChanged,
      ),
    );
  }
}

class _ClockActionButton extends StatefulWidget {
  const _ClockActionButton({
    required this.onTap,
    required this.color,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.isCompact,
    this.isDisabled = false,
  });

  final VoidCallback? onTap;
  final Color color;
  final IconData icon;
  final String label;
  final String subtitle;
  final bool isCompact;
  final bool isDisabled;

  @override
  State<_ClockActionButton> createState() => _ClockActionButtonState();
}

class _ClockActionButtonState extends State<_ClockActionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final opacity = widget.isDisabled ? 0.4 : 1.0;

    return MouseRegion(
      cursor: widget.isDisabled
          ? SystemMouseCursors.forbidden
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.isDisabled ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(
            horizontal: widget.isCompact ? 14 : 20,
            vertical: widget.isCompact ? 12 : 16,
          ),
          decoration: BoxDecoration(
            color: widget.color.withValues(
              alpha: _isHovered ? 0.18 : 0.1 * opacity,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.color.withValues(alpha: 0.35 * opacity),
              width: 1.5,
            ),
            boxShadow: _isHovered && !widget.isDisabled
                ? [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.15 * opacity),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.icon,
                  size: widget.isCompact ? 24 : 30,
                  color: widget.color.withValues(alpha: opacity),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.label,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.iconLabel?.withValues(alpha: opacity),
                  fontWeight: FontWeight.w700,
                  fontSize: widget.isCompact ? 12 : 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              SizedBox(
                width: widget.isCompact ? 120 : 150,
                child: Text(
                  widget.subtitle,
                  style: textTheme.bodySmall?.copyWith(
                    color: Colors.grey[500]?.withValues(alpha: opacity),
                    fontSize: widget.isCompact ? 10 : 11,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
