import 'package:flutter/material.dart';

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
                  Expanded(flex: 3, child: widget.rightSection),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
