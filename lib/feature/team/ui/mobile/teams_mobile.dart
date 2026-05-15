import 'package:flutter/material.dart';
import 'package:note_sondage/core/dependency_injection/dependency_injection.dart';
import 'package:note_sondage/feature/team/ui/bloc/team/team_bloc.dart';
import 'package:note_sondage/feature/team/ui/mobile/widgets/create_team_mobile.dart';
import 'package:note_sondage/feature/team/ui/mobile/widgets/team_display.dart';
import 'package:note_sondage/ui/mobile/widgets/login/tab_bar_component.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';

// 3. Modifica il tuo TeamsMobile widget per utilizzare i nuovi componenti
class TeamsMobile extends StatefulWidget {
  const TeamsMobile({super.key});

  @override
  State<TeamsMobile> createState() => _TeamsMobileState();
}

class _TeamsMobileState extends State<TeamsMobile>
    with SingleTickerProviderStateMixin {
  late TabController tabController;
  int currentViewType = 1;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
    tabController.addListener(_handleTabChange);
    getIt<TeamBloc>().add(LoadTeamsEvent());
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
    getIt<TeamBloc>().add(LoadTeamsEvent());
    // Torna alla tab dei team selezionati
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

    return SafeArea(
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

final List<Map<String, dynamic>> members = [
  {
    'id': '1',
    'name': 'Alice Johnson',
    'imageUrl': 'https://picsum.photos/id/237/200/300',
    'color': Colors.red,
  },
  {
    'id': '2',
    'name': 'Bob Smith',
    'imageUrl': 'https://picsum.photos/200/300?grayscale',
    'color': Colors.green,
  },
  {
    'id': '3',
    'name': 'Charlie Brown',
    'imageUrl': 'https://picsum.photos/seed/picsum/200/300',
    'color': Colors.blue,
  },
  {
    'id': '4',
    'name': 'Diana Prince',
    'imageUrl': 'https://example.com/diana.jpg',
    'color': Colors.purple,
  },
  {
    'id': '5',
    'name': 'Ethan Hunt',
    'imageUrl': 'https://example.com/ethan.jpg',
    'color': Colors.orange,
  },
  {
    'id': '6',
    'name': 'Fiona Glenanne',
    'imageUrl': 'https://example.com/fiona.jpg',
    'color': Colors.teal,
  },
];

final List<Map<String, dynamic>> teamsList = [
  {
    'teamId': '1131ff3e-7fa0-42a4-ba0c-de8baae29878',
    'teamName': 'Development Team',
    'teamFocus': 'Full Stack Development',
    'members': [
      {
        'id': '1',
        'name': 'Alice Johnson',
        'imageUrl': 'https://picsum.photos/id/237/200/300',
        'color': Colors.red,
      },
      {
        'id': '2',
        'name': 'Bob Smith',
        'imageUrl': 'https://picsum.photos/200/300?grayscale',
        'color': Colors.green,
      },
      {
        'id': '3',
        'name': 'Charlie Brown',
        'imageUrl': 'https://picsum.photos/seed/picsum/200/300',
        'color': Colors.blue,
      },
    ],
    'color': Colors.blue,
  },
  {
    'teamId': 'c3be890c-2a81-465e-ae6a-ced8db3a6636',
    'teamName': 'Design Team',
    'teamFocus': 'UI/UX Design',
    'members': [
      {
        'id': '4',
        'name': 'Diana Prince',
        'imageUrl': 'https://example.com/diana.jpg',
        'color': Colors.purple,
      },
      {
        'id': '5',
        'name': 'Ethan Hunt',
        'imageUrl': 'https://example.com/ethan.jpg',
        'color': Colors.orange,
      },
    ],
    'color': Colors.pink,
  },
  {
    'teamId': 'aa0218c2-8c23-4848-b699-236790a4b338',
    'teamName': 'Marketing Team',
    'teamFocus': 'Digital Marketing',
    'members': [
      {
        'id': '6',
        'name': 'Fiona Glenanne',
        'imageUrl': 'https://example.com/fiona.jpg',
        'color': Colors.teal,
      },
    ],
    'color': Color(0xFFAF5370),
  },
  {
    'teamId': '75ef20de-c6a2-45b4-b7ac-876d6ec0a73d',
    'teamName': 'QA Team',
    'teamFocus': 'Quality Assurance',
    'members': [
      {
        'id': '1',
        'name': 'Alice Johnson',
        'imageUrl': 'https://picsum.photos/id/237/200/300',
        'color': Colors.red,
      },
      {
        'id': '4',
        'name': 'Diana Prince',
        'imageUrl': 'https://example.com/diana.jpg',
        'color': Colors.purple,
      },
    ],
    'color': Color(0xFFFF3370),
  },
];
