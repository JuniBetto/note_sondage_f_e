import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_sondage/core/tutorial/app_tutorial_controller.dart';
import 'package:note_sondage/feature/auth/ui/bloc/auth_bloc.dart';
import 'package:note_sondage/feature/clocking/ui/bloc/clocking_bloc.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/feature/clocking/ui/widgets/button_clocking.dart';
import 'package:note_sondage/feature/clocking/ui/widgets/status_clockin_change_view.dart';
import 'package:note_sondage/feature/clocking/ui/widgets/status_clocking.dart';
import 'package:note_sondage/feature/team/ui/bloc/team/team_bloc.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:showcaseview/showcaseview.dart';

class ClockingMobile extends StatefulWidget {
  const ClockingMobile({super.key});

  @override
  State<ClockingMobile> createState() => _ClockingMobileState();
}

class _ClockingMobileState extends State<ClockingMobile> {
  final GlobalKey _statusKey = GlobalKey();
  final GlobalKey _actionKey = GlobalKey();
  final GlobalKey _historyKey = GlobalKey();
  String? _selectedTeamId;
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
      tutorialId: 'mobile-clocking',
      keys: <GlobalKey>[_statusKey, _actionKey, _historyKey],
    );
    AppTutorialController.registerReplayAction(
      tutorialId: 'mobile-clocking',
      action: () => AppTutorialController.replay(
        context: context,
        keys: <GlobalKey>[_statusKey, _actionKey, _historyKey],
      ),
    );
    _scheduleTutorial();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // ═══════════════════════════════
          // Status + Subtitle
          // ═══════════════════════════════
          Showcase(
            key: _statusKey,
            title: _isItalian(context) ? 'Stato attuale' : 'Current status',
            description: _isItalian(context)
                ? 'Questa sezione ti mostra subito lo stato della tua timbratura e le informazioni principali della giornata.'
                : 'This section gives you an instant view of your clocking status and the main information for the current day.',
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.bgNavbarSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.15)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.timer_rounded,
                          color: Colors.blue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        localization.personalStatusClockingActions,
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  StatusClocking(
                    isCompact: true,
                    selectedTeamId: _selectedTeamId,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ═══════════════════════════════
          // Action buttons — centered
          // ═══════════════════════════════
          Showcase(
            key: _actionKey,
            title: _isItalian(context)
                ? 'Azioni di timbratura'
                : 'Clocking actions',
            description: _isItalian(context)
                ? 'Da qui puoi selezionare la squadra corretta e registrare entrata o uscita.'
                : 'Use this area to pick the right team and register your clock-in or clock-out.',
            child: Center(
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
          ),

          const SizedBox(height: 16),

          // ═══════════════════════════════
          // Tracking section
          // ═══════════════════════════════
          Showcase(
            key: _historyKey,
            title: _isItalian(context)
                ? 'Storico timbrature'
                : 'Clocking history',
            description: _isItalian(context)
                ? 'Qui puoi controllare i cambi di stato e lo storico filtrato anche per squadra.'
                : 'Review status changes and history here, including the records filtered by the selected team.',
            child: StatusClockInChangeView(
              isMobile: true,
              selectedTeamId: _selectedTeamId,
            ),
          ),
        ],
      ),
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
        tutorialId: 'mobile-clocking',
        userId: context.read<AuthBloc>().state.user.uid,
        keys: <GlobalKey>[_statusKey, _actionKey, _historyKey],
      );
    });
  }

  bool _isItalian(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'it';
  }
}
