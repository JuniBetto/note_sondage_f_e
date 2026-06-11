import 'package:flutter/material.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';

/// Typedef per il builder della sidebar sinistra.
/// Riceve [isExpanded], [onToggle] e [lastIndexes] per costruire il widget.
typedef SidebarBuilder =
    Widget Function(
      bool isExpanded,
      VoidCallback onToggle,
      List<int> lastIndexes,
    );

class FullSidebar extends StatefulWidget {
  const FullSidebar({
    super.key,
    required this.leftSectionBuilder,
    required this.rightSection,
    this.expandedWidth = 250,
    this.collapsedWidth = 60,
    this.breakpoint = 800,
    this.animationDuration = const Duration(milliseconds: 200),
  });

  /// Builder per la sidebar sinistra.
  final SidebarBuilder leftSectionBuilder;

  /// Contenuto della sezione destra.
  final Widget rightSection;

  /// Larghezza della sidebar quando è espansa.
  final double expandedWidth;

  /// Larghezza della sidebar quando è compatta.
  final double collapsedWidth;

  /// Breakpoint per il responsive automatico.
  final double breakpoint;

  /// Durata dell'animazione di apertura/chiusura.
  final Duration animationDuration;

  @override
  State<FullSidebar> createState() => _FullSidebarState();
}

class _FullSidebarState extends State<FullSidebar> {
  List<int> lastIndexes = [];
  bool? _manualExpanded;

  void _toggleSidebarSize(bool currentIsExpanded) {
    setState(() {
      _manualExpanded = !currentIsExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final separatorColor = colorScheme.brightness == Brightness.dark
        ? colorScheme.outlineVariant.withValues(alpha: 0.9)
        : (colorScheme.borderColor?.withValues(alpha: 0.85) ??
              colorScheme.outlineVariant);
    final rightPanelColor = colorScheme.brightness == Brightness.dark
        ? colorScheme.surface.withValues(alpha: 0.08)
        : Colors.transparent;

    return LayoutBuilder(
      builder: (context, constraints) {
        final autoExpanded = constraints.maxWidth > widget.breakpoint;
        final isExpanded = _manualExpanded ?? autoExpanded;

        return Column(
          children: [
            const SizedBox(height: 4),
            Expanded(
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: widget.animationDuration,
                    width: isExpanded
                        ? widget.expandedWidth
                        : widget.collapsedWidth,
                    child: widget.leftSectionBuilder(
                      isExpanded,
                      () => _toggleSidebarSize(isExpanded),
                      lastIndexes,
                    ),
                  ),
                  Container(
                    width: 1,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    color: separatorColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: rightPanelColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: widget.rightSection,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
