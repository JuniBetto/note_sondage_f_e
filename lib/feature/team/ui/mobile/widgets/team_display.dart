import 'package:flutter/material.dart';
import 'package:note_sondage/feature/team/ui/widgets/responsive_grid_teams.dart';
import 'package:note_sondage/feature/team/ui/widgets/visual_type.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';

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
  late int isGridView;

  @override
  void initState() {
    super.initState();
    isGridView = widget.initialViewType;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
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
                widget.onViewChanged(1);
              },
              onTap2: () {
                setState(() {
                  isGridView = 2;
                });
                widget.onViewChanged(2);
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
                    color: colorScheme.homeSecondary!.withValues(alpha: 0.2),
                    blurRadius: 8,
                    spreadRadius: 2,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ResponsiveGridTeams(
                items: widget.teams,
                isRow: isGridView == 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
