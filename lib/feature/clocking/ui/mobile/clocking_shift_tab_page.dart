import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:note_sondage/core/tutorial/app_tutorial_controller.dart';
import 'package:note_sondage/feature/clocking/ui/mobile/clocking_mobile.dart';
import 'package:note_sondage/feature/event/ui/mobile/event_mobile_widget.dart';
import 'package:note_sondage/feature/shift/ui/bloc/shift_bloc.dart';
import 'package:note_sondage/feature/shift/ui/mobile/shift_mobile_widget.dart';
import 'package:note_sondage/feature/task/ui/mobile/task_mobile_widget.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/ui/mobile/widgets/login/tab_bar_component.dart';

/// Tab page that hosts Clocking, Shifts, Tasks and Events,
/// using the same pill-style tab bar as Login/Register and Teams.
class ClockingShiftTabPage extends StatefulWidget {
  const ClockingShiftTabPage({super.key});

  /// Set this before navigating to index 3 to land directly on a specific tab.
  /// It is reset to 0 after the first build so subsequent navigations start
  /// on the default Clocking tab.
  static int requestedInitialTab = 0;
  static String? requestedEventInitialTeamId;
  static String? requestedEventInitialEventId;

  @override
  State<ClockingShiftTabPage> createState() => _ClockingShiftTabPageState();
}

class _ClockingShiftTabPageState extends State<ClockingShiftTabPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final String? _eventInitialTeamId;
  late final String? _eventInitialEventId;

  @override
  void initState() {
    super.initState();
    final initialTab = ClockingShiftTabPage.requestedInitialTab;
    _eventInitialTeamId = _normalizeOptionalId(
      ClockingShiftTabPage.requestedEventInitialTeamId,
    );
    _eventInitialEventId = _normalizeOptionalId(
      ClockingShiftTabPage.requestedEventInitialEventId,
    );
    ClockingShiftTabPage.requestedInitialTab = 0; // reset for next navigation
    ClockingShiftTabPage.requestedEventInitialTeamId = null;
    ClockingShiftTabPage.requestedEventInitialEventId = null;
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: initialTab,
    );
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) setState(() {});
  }

  String? _normalizeOptionalId(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    AppTutorialController.registerReplayAction(
      tutorialId: 'mobile-main-3',
      action: () => AppTutorialController.replayRegistered(
        context: context,
        tutorialId: _tabController.index == 0
            ? 'mobile-clocking'
            : _tabController.index == 1
            ? 'mobile-shifts'
            : _tabController.index == 2
            ? 'mobile-tasks'
            : 'mobile-events',
      ),
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // ── Pill-style tab bar ──────────────────────────────
            TabBarComponent(
              tabController: _tabController,
              setToUpdate: setState,
              childTab1: Text(loc.clockingInOut),
              childTab2: Text(loc.myShifts),
              childTab3: const Text('Task'),
              childTab4: Text(loc.eventPageTitle),
            ),

            const SizedBox(height: 8),
            Divider(height: 2, color: Colors.grey[400]),
            const SizedBox(height: 8),

            // ── Tab content ─────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1 — Clock In/Out
                  const ClockingMobile(),

                  // Tab 2 — My Shifts
                  BlocProvider<ShiftBloc>.value(
                    value: GetIt.instance<ShiftBloc>(),
                    child: const ShiftMobileWidget(),
                  ),
                  TaskMobileWidget(
                    isActive: _tabController.index == 2,
                    isTabTransitioning: _tabController.indexIsChanging,
                  ),
                  EventMobileWidget(
                    initialTeamId: _eventInitialTeamId,
                    initialEventId: _eventInitialEventId,
                    isActive: _tabController.index == 3,
                    isTabTransitioning: _tabController.indexIsChanging,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
