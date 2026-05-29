import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_sondage/core/tutorial/app_tutorial_controller.dart';
import 'package:note_sondage/feature/auth/ui/bloc/auth_bloc.dart';
import 'package:note_sondage/feature/clocking/ui/bloc/clocking_bloc.dart';
import 'package:note_sondage/feature/clocking/ui/widgets/button_clocking.dart';
import 'package:note_sondage/feature/clocking/ui/widgets/clocking_date_selector.dart';
import 'package:note_sondage/feature/clocking/ui/widgets/status_clockin_change_view.dart';
import 'package:note_sondage/feature/clocking/ui/widgets/status_clocking.dart';
import 'package:note_sondage/feature/team/ui/bloc/team/team_bloc.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:table_calendar/table_calendar.dart';

class ClockingWeb extends StatefulWidget {
  const ClockingWeb({super.key});

  @override
  State<ClockingWeb> createState() => _ClockingWebState();
}

class _ClockingWebState extends State<ClockingWeb> {
  final GlobalKey _headerKey = GlobalKey();
  String? _selectedTeamId;
  DateTime _selectedDate = _normalizeDate(DateTime.now());
  CalendarFormat _calendarFormat = CalendarFormat.week;
  bool _tutorialScheduled = false;

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

    AppTutorialController.registerTargets(
      tutorialId: 'web-clocking',
      keys: <GlobalKey>[_headerKey],
    );
    AppTutorialController.registerReplayAction(
      tutorialId: 'web-clocking',
      action: () => AppTutorialController.replay(
        context: context,
        keys: <GlobalKey>[_headerKey],
      ),
    );
    AppTutorialController.registerReplayAction(
      tutorialId: 'web-main-3',
      action: () => AppTutorialController.replayRegistered(
        context: context,
        tutorialId: 'web-clocking',
      ),
    );
    _scheduleTutorial();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 700;
        final actionPanelWidth = constraints.maxWidth >= 1100 ? 420.0 : 360.0;

        return SingleChildScrollView(
          child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ═══════════════════════════════
              // Header
              // ═══════════════════════════════
              Showcase(
                key: _headerKey,
                title: _isItalian(context)
                    ? 'Panoramica timbratura'
                    : 'Clocking overview',
                description: _isItalian(context)
                    ? 'Questa intestazione riassume l\'area di timbratura e il suo scopo principale.'
                    : 'This header introduces the clocking area and its main purpose.',
                child: Container(
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
                              localization.clockingOverviewTitle,
                              style: textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.iconLabel,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              localization.clockingOverviewDescription,
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
              ),
              const SizedBox(height: 20),
              ClockingDateSelector(
                selectedDate: _selectedDate,
                calendarFormat: _calendarFormat,
                onSelectedDateChanged: (value) {
                  if (!mounted) return;
                  setState(() => _selectedDate = _normalizeDate(value));
                },
                onFormatChanged: (value) {
                  if (!mounted) return;
                  setState(() => _calendarFormat = value);
                },
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
                            selectedDate: _selectedDate,
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: ButtonClocking(
                              isCompact: true,
                              selectedTeamId: _selectedTeamId,
                              selectedDate: _selectedDate,
                              onSelectedTeamChanged: (value) {
                                if (!mounted) return;
                                setState(() => _selectedTeamId = value);
                                context.read<ClockingBloc>().add(
                                  LoadClockingRecordsEvent(teamId: value),
                                );
                              },
                              onSelectedDateChanged: (value) {
                                if (!mounted) return;
                                setState(() => _selectedDate = value);
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
                              selectedDate: _selectedDate,
                            ),
                          ),
                          const SizedBox(width: 20),
                          SizedBox(
                            width: actionPanelWidth,
                            child: ButtonClocking(
                              selectedTeamId: _selectedTeamId,
                              selectedDate: _selectedDate,
                              onSelectedTeamChanged: (value) {
                                if (!mounted) return;
                                setState(() => _selectedTeamId = value);
                                context.read<ClockingBloc>().add(
                                  LoadClockingRecordsEvent(teamId: value),
                                );
                              },
                              onSelectedDateChanged: (value) {
                                if (!mounted) return;
                                setState(() => _selectedDate = value);
                              },
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 20),

              // ═══════════════════════════════
              // Tracking table section
              // ═══════════════════════════════
              StatusClockInChangeView(
                selectedTeamId: _selectedTeamId,
                selectedDate: _selectedDate,
              ),
            ],
          ),
          ), // SingleChildScrollView
        );
      },
    );
  }

  void _scheduleTutorial() {
    if (_tutorialScheduled) {
      return;
    }
    _tutorialScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }
      await AppTutorialController.showIfNeeded(
        context: context,
        tutorialId: 'web-clocking',
        userId: context.read<AuthBloc>().state.user.uid,
        keys: <GlobalKey>[_headerKey],
      );
    });
  }

  bool _isItalian(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'it';
  }

  static DateTime _normalizeDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
