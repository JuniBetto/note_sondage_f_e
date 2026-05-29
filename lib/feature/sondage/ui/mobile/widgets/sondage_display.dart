import 'package:flutter/material.dart';
import 'package:note_sondage/feature/sondage/domain/entities/sondage_entity.dart';
import 'package:note_sondage/feature/sondage/ui/widgets/responsive_grid_sondages.dart';
import 'package:note_sondage/feature/team/ui/widgets/visual_type.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';

class SondageDisplay extends StatefulWidget {
  final List<SondageEntity> sondages;
  final Function(int) onViewChanged;
  final int initialViewType;
  final ValueChanged<String> onDeleteTap;
  final ValueChanged<SondageEntity> onEditTap;

  const SondageDisplay({
    Key? key,
    required this.sondages,
    required this.onViewChanged,
    required this.onDeleteTap,
    required this.onEditTap,
    this.initialViewType = 1,
  }) : super(key: key);

  @override
  State<SondageDisplay> createState() => _TeamsDisplaySectionState();
}

class _TeamsDisplaySectionState extends State<SondageDisplay> {
  late int isGridView;

  @override
  void initState() {
    super.initState();
    isGridView = widget.initialViewType;
  }

  @override
  void didUpdateWidget(covariant SondageDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialViewType != widget.initialViewType) {
      isGridView = widget.initialViewType;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final orientation = MediaQuery.orientationOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final useLandscapeCompactLayout =
            orientation == Orientation.landscape && constraints.maxHeight < 560;
        final sectionSpacing = useLandscapeCompactLayout ? 8.0 : 16.0;
        final toggleIconSize = useLandscapeCompactLayout ? 22.0 : 28.0;
        final sondageList = SizedBox(
          width: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.borderColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.bgNavbarSurface!.withValues(alpha: 0.2),
                  blurRadius: 8,
                  spreadRadius: 2,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ResponsiveGridSondages(
              items: widget.sondages,
              isRow: isGridView == 1,
              onDeleteTap: widget.onDeleteTap,
              onEditTap: widget.onEditTap,
              shrinkWrapLayout: useLandscapeCompactLayout,
            ),
          ),
        );

        final header = Align(
          alignment: Alignment.centerRight,
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
        );

        if (!useLandscapeCompactLayout) {
          return Column(
            children: [
              header,
              SizedBox(height: sectionSpacing),
              Expanded(child: sondageList),
            ],
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            header,
            SizedBox(height: sectionSpacing),
            sondageList,
          ],
        );
      },
    );
  }
}
