import 'package:flutter/material.dart';
import 'package:note_sondage/feature/team/ui/mobile/teams_mobile.dart';
import 'package:note_sondage/feature/team/ui/web/teams_web_skeleton.dart';
import 'package:note_sondage/feature/team/ui/web/widgets/create_team_web.dart';
import 'package:note_sondage/feature/team/ui/widgets/responsive_grid_teams.dart';
import 'package:note_sondage/feature/team/ui/widgets/visual_type.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/widgets/custom_app_button.dart';
import 'package:note_sondage/ui/widgets/custom_dialog.dart';

class TeamsWeb extends StatefulWidget {
  const TeamsWeb({super.key, this.title = "Create Team"});
  final String title;

  @override
  State<TeamsWeb> createState() => _TeamsWebState();
}

class _TeamsWebState extends State<TeamsWeb> {
  int isGridView = 1;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Simula caricamento dati - sostituire con chiamata API reale
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mostra skeleton durante il caricamento
    if (_isLoading) {
      return const TeamsWebSkeleton();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox.expand(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.bgNavbarSurface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 8.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    CustomAppButton(
                      elevation: 4,
                      backgroundColor: colorScheme.selectionColor,
                      type: ButtonType.outlined,
                      isActive: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Icon(
                          Icons.add,
                          color: colorScheme.iconLabel,
                          size: 34,
                        ),
                      ),
                      onPressed: () {
                        CustomDialog(
                          title: widget.title,
                          width: 700,
                          child: CreateTeamWeb(),
                        ).show(context);
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Divider(height: 4, color: colorScheme.borderColor),
              SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
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
              ),
              SizedBox(height: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 8.0,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.bgNavbarSurface!,
                            blurRadius: 8,
                            spreadRadius: 2,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ResponsiveGridTeams(
                        items: teamsList,
                        isRow: isGridView == 1,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
