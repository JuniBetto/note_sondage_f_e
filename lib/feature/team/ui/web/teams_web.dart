import 'package:flutter/material.dart';
import 'package:note_sondage/feature/team/ui/mobile/teams_mobile.dart';
import 'package:note_sondage/feature/team/ui/web/widgets/create_team_web.dart';
import 'package:note_sondage/feature/team/ui/widgets/responsive_grid_teams.dart';
import 'package:note_sondage/feature/team/ui/widgets/visual_type.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/widgets/custom_dialog.dart';

class TeamsWeb extends StatefulWidget {
  const TeamsWeb({super.key, this.title = "Create Team"});
  final String title;

  @override
  State<TeamsWeb> createState() => _TeamsWebState();
}

class _TeamsWebState extends State<TeamsWeb> {
  int isGridView = 1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final localization = AppLocalizations.of(context)!;

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
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    FilledButton.icon(
                      onPressed: () {
                        CustomDialog(
                          title: widget.title,
                          width: 700,
                          child: CreateTeamWeb(),
                        ).show(context);
                      },
                      icon: const Icon(Icons.group_add_rounded, size: 20),
                      label: Text(
                        localization.createTeam,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF7C4DFF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                      ),
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
