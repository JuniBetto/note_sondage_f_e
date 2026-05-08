import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_sondage/feature/clocking/ui/bloc/clocking_bloc.dart';
import 'package:note_sondage/feature/clocking/ui/widgets/button_clocking.dart';
import 'package:note_sondage/feature/clocking/ui/widgets/status_clockin_change_view.dart';
import 'package:note_sondage/feature/clocking/ui/widgets/status_clocking.dart';
import 'package:note_sondage/feature/team/ui/bloc/team/team_bloc.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';

class ClockingWeb extends StatefulWidget {
  const ClockingWeb({super.key});

  @override
  State<ClockingWeb> createState() => _ClockingWebState();
}

class _ClockingWebState extends State<ClockingWeb> {
  String? _selectedTeamId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ClockingBloc>().add(const LoadClockingRecordsEvent());
      context.read<TeamBloc>().add(LoadTeamsEvent());
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final localization = AppLocalizations.of(context)!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 700;

        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: [
              // ═══════════════════════════════
              // Header
              // ═══════════════════════════════
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.bgNavbarSurface,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.timer_rounded,
                        color: Colors.blue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            localization.clockingInOut,
                            style: textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.iconLabel,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            localization.personalStatusClockingActions,
                            style: textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ═══════════════════════════════
              // Status + Actions card
              // ═══════════════════════════════
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.bgNavbarSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.blue.withValues(alpha: 0.15),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: isSmallScreen
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          StatusClocking(
                            isCompact: true,
                            selectedTeamId: _selectedTeamId,
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: ButtonClocking(
                              isCompact: true,
                              selectedTeamId: _selectedTeamId,
                              onSelectedTeamChanged: (value) {
                                if (!mounted) return;
                                setState(() => _selectedTeamId = value);
                                context.read<ClockingBloc>().add(
                                  LoadClockingRecordsEvent(teamId: value),
                                );
                              },
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: StatusClocking(
                              isCompact: false,
                              selectedTeamId: _selectedTeamId,
                            ),
                          ),
                          const SizedBox(width: 20),
                          ButtonClocking(
                            selectedTeamId: _selectedTeamId,
                            onSelectedTeamChanged: (value) {
                              if (!mounted) return;
                              setState(() => _selectedTeamId = value);
                              context.read<ClockingBloc>().add(
                                LoadClockingRecordsEvent(teamId: value),
                              );
                            },
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 20),

              // ═══════════════════════════════
              // Tracking table section
              // ═══════════════════════════════
              StatusClockInChangeView(selectedTeamId: _selectedTeamId),
            ],
          ),
        );
      },
    );
  }
}
