import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_sondage/core/dependency_injection/dependency_injection.dart';
import 'package:note_sondage/core/tutorial/app_tutorial_controller.dart';
import 'package:note_sondage/feature/auth/ui/bloc/auth_bloc.dart';
import 'package:note_sondage/feature/team/ui/bloc/team/team_bloc.dart';
import 'package:note_sondage/feature/team/ui/web/widgets/create_team_web.dart';
import 'package:note_sondage/feature/team/ui/widgets/responsive_grid_teams.dart';
import 'package:note_sondage/feature/team/ui/widgets/visual_type.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/widgets/app_snackbar.dart';
import 'package:note_sondage/ui/widgets/app_search_field.dart';
import 'package:note_sondage/ui/widgets/custom_dialog.dart';
import 'package:note_sondage/core/tutorial/debug_showcase.dart';

class TeamsWeb extends StatefulWidget {
  const TeamsWeb({super.key, this.title = "Create Team"});
  final String title;

  @override
  State<TeamsWeb> createState() => _TeamsWebState();
}

class _TeamsWebState extends State<TeamsWeb> {
  late final TeamBloc _teamBloc;
  final GlobalKey _createButtonKey = GlobalKey();
  final GlobalKey _viewToggleKey = GlobalKey();
  final GlobalKey _teamListKey = GlobalKey();
  final TextEditingController _searchController = TextEditingController();
  int isGridView = 1;
  bool _tutorialScheduled = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _teamBloc = getIt<TeamBloc>();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleTeamCreated() {
    // The TeamBloc now updates the local list optimistically and reconciles
    // with the server in background, so no blocking full reload is needed here.
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final localization = AppLocalizations.of(context)!;

    AppTutorialController.registerTargets(
      tutorialId: 'web-team-list',
      keys: <GlobalKey>[_createButtonKey, _viewToggleKey, _teamListKey],
    );
    AppTutorialController.registerReplayAction(
      tutorialId: 'web-team-list',
      action: () => AppTutorialController.replay(
        context: context,
        keys: <GlobalKey>[_createButtonKey, _viewToggleKey, _teamListKey],
      ),
    );
    AppTutorialController.registerReplayAction(
      tutorialId: 'web-main-1',
      action: () => AppTutorialController.replayRegistered(
        context: context,
        tutorialId: 'web-team-list',
      ),
    );
    _scheduleTutorial();

    return BlocListener<TeamBloc, TeamState>(
      bloc: _teamBloc,
      listenWhen: (_, current) => current is TeamError,
      listener: (context, state) {
        if (state is TeamError) {
          AppSnackBar.showError(context, state.message);
        }
      },
      child: SizedBox.expand(
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Showcase(
                            key: _createButtonKey,
                            title: _isItalian(context)
                                ? 'Nuova squadra'
                                : 'New team',
                            description: _isItalian(context)
                                ? 'Apri qui la sotto-pagina di creazione per configurare una nuova squadra con nome, colore e membri.'
                                : 'Open the creation subpage here to configure a new team with its name, color, and members.',
                            child: FilledButton.icon(
                              onPressed: () {
                                CustomDialog(
                                  title: widget.title,
                                  width: 700,
                                  child: CreateTeamWeb(
                                    onTeamCreated: _handleTeamCreated,
                                  ),
                                ).show(context);
                              },
                              icon: const Icon(
                                Icons.group_add_rounded,
                                size: 20,
                              ),
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
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: AppSearchField(
                          controller: _searchController,
                          hintText: _isItalian(context)
                              ? 'Cerca team per nome o descrizione'
                              : 'Search teams by name or description',
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
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
                      Showcase(
                        key: _viewToggleKey,
                        title: _isItalian(context)
                            ? 'Vista della lista'
                            : 'List layout',
                        description: _isItalian(context)
                            ? 'Puoi cambiare il modo in cui le squadre vengono mostrate, passando da griglia a lista.'
                            : 'Switch how teams are displayed here by choosing between a grid and a list layout.',
                        child: VisualType(
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
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                Expanded(
                  child: Showcase(
                    key: _teamListKey,
                    title: _isItalian(context)
                        ? 'Elenco delle squadre'
                        : 'Teams area',
                    description: _isItalian(context)
                        ? 'Qui trovi tutte le squadre disponibili. Un click su una card apre il dettaglio della squadra selezionata.'
                        : 'This area contains all available teams. Click any card to open the selected team detail page.',
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                      child: SizedBox(
                        width: double.infinity,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: colorScheme.borderColor,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    (colorScheme.bgNavbarSurface ??
                                            Colors.black)
                                        .withValues(alpha: 0.2),
                                blurRadius: 8,
                                spreadRadius: 2,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ResponsiveGridTeams(
                            items: const <Map<String, dynamic>>[],
                            isRow: isGridView == 1,
                            searchQuery: _searchQuery,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
        tutorialId: 'web-team-list',
        userId: context.read<AuthBloc>().state.user.uid,
        keys: <GlobalKey>[_createButtonKey, _viewToggleKey, _teamListKey],
      );
    });
  }

  bool _isItalian(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'it';
  }
}
