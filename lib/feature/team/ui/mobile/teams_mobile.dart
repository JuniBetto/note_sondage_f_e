import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_sondage/core/tutorial/app_tutorial_controller.dart';
import 'package:note_sondage/core/dependency_injection/dependency_injection.dart';
import 'package:note_sondage/feature/team/ui/bloc/team/team_bloc.dart';
import 'package:note_sondage/feature/team/ui/mobile/widgets/create_team_mobile.dart';
import 'package:note_sondage/feature/team/ui/mobile/widgets/team_display.dart';
import 'package:note_sondage/ui/mobile/widgets/login/tab_bar_component.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/ui/widgets/app_snackbar.dart';

// 3. Modifica il tuo TeamsMobile widget per utilizzare i nuovi componenti
class TeamsMobile extends StatefulWidget {
  const TeamsMobile({super.key});

  @override
  State<TeamsMobile> createState() => _TeamsMobileState();
}

class _TeamsMobileState extends State<TeamsMobile>
    with SingleTickerProviderStateMixin {
  late final TeamBloc _teamBloc;
  late TabController tabController;
  int currentViewType = 1;

  @override
  void initState() {
    super.initState();
    _teamBloc = getIt<TeamBloc>();
    tabController = TabController(length: 2, vsync: this);
    tabController.addListener(_handleTabChange);
    _teamBloc.add(LoadTeamsEvent());
  }

  void _handleTabChange() {
    if (tabController.indexIsChanging) {
      setState(() {
        // Reset della view quando cambi tab (opzionale)
        // currentViewType = 1;
      });
    }
  }

  void _handleViewTypeChanged(int viewType) {
    setState(() {
      currentViewType = viewType;
    });
  }

  void _handleTeamCreated() {
    // Torna alla tab dei team selezionati: la lista e la cache sono gia'
    // aggiornate ottimisticamente dal bloc.
    tabController.animateTo(0);
  }

  @override
  void dispose() {
    tabController.removeListener(_handleTabChange);
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;

    AppTutorialController.registerReplayAction(
      tutorialId: 'mobile-main-1',
      action: () => AppTutorialController.replayRegistered(
        context: context,
        tutorialId: tabController.index == 0
            ? 'mobile-team-list'
            : 'mobile-team-create',
      ),
    );

    return BlocListener<TeamBloc, TeamState>(
      bloc: _teamBloc,
      listenWhen: (_, current) => current is TeamError,
      listener: (context, state) {
        if (state is TeamError) {
          AppSnackBar.showError(context, state.message);
        }
      },
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TabBarComponent(
                childTab1: Text(
                  localization.selectedTeam,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                childTab2: Text(
                  localization.createTeam,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                tabController: tabController,
                setToUpdate: setState,
              ),
              SizedBox(height: 8),
              Divider(height: 2, color: Colors.grey[400]),
              SizedBox(height: 16),

              // Contenuto dinamico basato sulla tab selezionata
              Expanded(
                child: TabBarView(
                  controller: tabController,
                  children: [
                    // Prima tab: Visualizzazione team
                    TeamsDisplay(
                      teams: const <Map<String, dynamic>>[],
                      onViewChanged: _handleViewTypeChanged,
                      initialViewType: currentViewType,
                    ),

                    // Seconda tab: Creazione team
                    CreateTeamMobile(onTeamCreated: _handleTeamCreated),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/*class TeamsMobile extends StatefulWidget {
  const TeamsMobile({super.key});

  @override
  State<TeamsMobile> createState() => _TeamsMobileState();
}

class _TeamsMobileState extends State<TeamsMobile>
    with SingleTickerProviderStateMixin {
  late TabController tabController;

  int isGridView = 1;

  /*void toggleView() {
    setState(() {
      isGridView = isGridView == 1 ? 2 : 1;
    });
  }*/

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    tabController = TabController(length: 2, vsync: this);
  }

  void _handleTabSelection() {
    if (tabController.indexIsChanging) {
      setState(() {
        // Forza il rebuild quando cambia il tab
      });
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    tabController.removeListener(_handleTabSelection);
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TabBarComponent(
              childTab1: Text(
                localization.selectedTeam,
                style: TextStyle(
                  color: tabController.index == 1
                      ? ColorPalette.primary[6]
                      : Colors.grey[600],
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              childTab2: Text(
                localization.createTeam,
                style: TextStyle(
                  color: tabController.index == 1
                      ? ColorPalette.primary[6]
                      : Colors.grey[600],
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              tabController: tabController,
              setToUpdate: setState,
            ),
            SizedBox(height: 8),
            Divider(height: 2, color: Colors.grey[400]),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                VisualType(
                  isActive1: isGridView == 1,
                  isActive2: isGridView == 2,
                  color: colorScheme.cursorColor,
                  iconData1: Icons.window_sharp,
                  iconData2: Icons.list,
                  onTap1: () {
                    setState(() {
                      isGridView = 1;
                    });
                  },
                  onTap2: () {
                    setState(() {
                      isGridView = 2;
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 16),
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colorScheme.borderColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.bgNavbarSurface!.withValues(
                          alpha: 0.2,
                        ),
                        blurRadius: 8,
                        spreadRadius: 2,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ResponsiveGridTeams(
                    items: teams,
                    isRow: isGridView == 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}*/
