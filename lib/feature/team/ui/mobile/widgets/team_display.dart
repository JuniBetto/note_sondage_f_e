import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_sondage/core/tutorial/app_tutorial_controller.dart';
import 'package:note_sondage/feature/auth/ui/bloc/auth_bloc.dart';
import 'package:note_sondage/feature/team/ui/widgets/responsive_grid_teams.dart';
import 'package:note_sondage/feature/team/ui/widgets/visual_type.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:showcaseview/showcaseview.dart';

class TeamsDisplay extends StatefulWidget {
  final List<Map<String, dynamic>> teams;
  final Function(int) onViewChanged;
  final int initialViewType;

  const TeamsDisplay({
    Key? key,
    required this.teams,
    required this.onViewChanged,
    this.initialViewType = 1,
  }) : super(key: key);

  @override
  State<TeamsDisplay> createState() => _TeamsDisplaySectionState();
}

class _TeamsDisplaySectionState extends State<TeamsDisplay> {
  final GlobalKey _viewToggleKey = GlobalKey();
  final GlobalKey _teamListKey = GlobalKey();
  late int isGridView;
  bool _tutorialScheduled = false;

  @override
  void initState() {
    super.initState();
    isGridView = widget.initialViewType;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    AppTutorialController.registerTargets(
      tutorialId: 'mobile-team-list',
      keys: <GlobalKey>[_viewToggleKey, _teamListKey],
    );
    AppTutorialController.registerReplayAction(
      tutorialId: 'mobile-team-list',
      action: () => AppTutorialController.replay(
        context: context,
        keys: <GlobalKey>[_viewToggleKey, _teamListKey],
      ),
    );
    _scheduleTutorial();

    return LayoutBuilder(
      builder: (context, constraints) {
        final orientation = MediaQuery.orientationOf(context);
        final useLandscapeCompactLayout =
            orientation == Orientation.landscape && constraints.maxHeight < 560;
        final sectionSpacing = useLandscapeCompactLayout ? 8.0 : 16.0;
        final toggleIconSize = useLandscapeCompactLayout ? 22.0 : 28.0;
        final teamList = Showcase(
          key: _teamListKey,
          title: _isItalian(context) ? 'Elenco squadre' : 'Team list',
          description: _isItalian(context)
              ? 'Questa sezione raccoglie tutte le tue squadre. Tocca una squadra per aprirne i dettagli o gestirla più da vicino.'
              : 'This section contains all of your teams. Tap any team to open its details and manage it more closely.',
          child: SizedBox(
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.borderColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.homeSecondary!.withValues(alpha: 0.2),
                    blurRadius: 8,
                    spreadRadius: 2,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ResponsiveGridTeams(
                items: widget.teams,
                isRow: isGridView == 1,
                shrinkWrapLayout: useLandscapeCompactLayout,
              ),
            ),
          ),
        );

        final header = Align(
          alignment: Alignment.centerRight,
          child: Showcase(
            key: _viewToggleKey,
            title: _isItalian(context) ? 'Vista team' : 'Team layout',
            description: _isItalian(context)
                ? 'Qui scegli se vedere i team in griglia o in lista, così puoi leggere più velocemente o avere una panoramica più visuale.'
                : 'Switch between grid and list layouts here depending on whether you want a quick visual overview or a denser list.',
            child: VisualType(
              size: toggleIconSize,
              isActive1: isGridView == 1,
              isActive2: isGridView == 2,
              color: colorScheme.cursorColor,
              iconData1: Icons.window_sharp,
              iconData2: Icons.list,
              onTap1: () {
                setState(() {
                  isGridView = 1;
                });
                widget.onViewChanged(1);
              },
              onTap2: () {
                setState(() {
                  isGridView = 2;
                });
                widget.onViewChanged(2);
              },
            ),
          ),
        );

        if (!useLandscapeCompactLayout) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              SizedBox(height: sectionSpacing),
              Expanded(child: teamList),
            ],
          );
        }

        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                header,
                SizedBox(height: sectionSpacing),
                teamList,
              ],
            ),
          ),
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
        tutorialId: 'mobile-team-list',
        userId: context.read<AuthBloc>().state.user.uid,
        keys: <GlobalKey>[_viewToggleKey, _teamListKey],
      );
    });
  }

  bool _isItalian(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'it';
  }
}
