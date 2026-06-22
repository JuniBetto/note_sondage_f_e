import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:note_sondage/core/tutorial/app_tutorial_controller.dart';
import 'package:note_sondage/feature/clocking/ui/mobile/clocking_mobile.dart';
import 'package:note_sondage/feature/shift/ui/bloc/shift_bloc.dart';
import 'package:note_sondage/feature/shift/ui/mobile/shift_mobile_widget.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/ui/mobile/widgets/login/tab_bar_component.dart';

/// Tab page that hosts "Clock In/Out" and "My Shifts" as two tabs,
/// using the same pill-style tab bar as Login/Register and Teams.
class ClockingShiftTabPage extends StatefulWidget {
  const ClockingShiftTabPage({super.key});

  /// Set this to 1 before navigating to index 3 to land directly on Shifts.
  /// It is reset to 0 after the first build so subsequent navigations start
  /// on the default Clocking tab.
  static int requestedInitialTab = 0;

  @override
  State<ClockingShiftTabPage> createState() => _ClockingShiftTabPageState();
}

class _ClockingShiftTabPageState extends State<ClockingShiftTabPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final initialTab = ClockingShiftTabPage.requestedInitialTab;
    ClockingShiftTabPage.requestedInitialTab = 0; // reset for next navigation
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: initialTab,
    );
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) setState(() {});
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
            : 'mobile-shifts',
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
