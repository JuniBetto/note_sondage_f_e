import 'package:flutter/material.dart';
import 'package:note_sondage/feature/team/ui/mobile/teams_mobile.dart';
import 'package:note_sondage/feature/team/ui/widgets/responsive_grid_teams.dart';
import 'package:note_sondage/feature/team/ui/widgets/visual_type.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/mobile/widgets/header_page.dart';

class SelectTeamPage extends StatefulWidget {
  const SelectTeamPage({super.key});

  @override
  State<SelectTeamPage> createState() => _SelectTeamPageState();
}

class _SelectTeamPageState extends State<SelectTeamPage> {
  int isGridView = 1;
  List<Map<String, dynamic>> teams = teamsList;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: HeaderPage(
        showBackButton: true,
        title: localization.selectedTeam,
        onBackPressed: () {
          Navigator.pop(context);
        },
      ),
      backgroundColor: colorScheme.bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
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
                      isSelectionMode: true,
                      onTeamSelected: (selectedTeam) {
                        // Torna indietro con il team selezionato
                        Navigator.pop(context, selectedTeam);
                      },
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
