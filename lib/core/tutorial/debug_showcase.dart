import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';

export 'package:showcaseview/showcaseview.dart';

bool get isInspectorSelectionActive {
  if (!kDebugMode) {
    return false;
  }

  final binding = WidgetsBinding.instance;
  return binding.debugWidgetInspectorSelectionOnTapEnabled.value;
}

/// Keeps the tutorial tooltip (and its Skip/Back/Next buttons) clear of the
/// system navigation bar. showcaseview lays the tooltip out against the full
/// overlay and ignores system insets, so on Android — where the app draws
/// behind the navigation bar — a tooltip placed low on the screen puts its
/// buttons underneath the device's own buttons.
///
/// Its only screen-edge knob (`toolTipMargin`) applies to every side and would
/// squeeze the tooltip until the three buttons overflow, so instead the bottom
/// inset is added to the tooltip's own bottom padding: the buttons sit above
/// the bar and the package's placement logic sees the taller tooltip. A
/// tooltip forced above its target can't reach the bar, so it is left alone.
///
/// A function rather than a widget subclass because `Showcase` needs the
/// [GlobalKey] itself as its key, which ShowcaseView uses to find it.
Widget appShowcase({
  required GlobalKey key,
  required Widget child,
  String? title,
  String? description,
  TooltipPosition? tooltipPosition,
}) {
  return Builder(
    builder: (context) {
      final bottomInset = tooltipPosition == TooltipPosition.top
          ? 0.0
          : MediaQuery.viewPaddingOf(context).bottom;
      return Showcase(
        key: key,
        title: title,
        description: description,
        tooltipPosition: tooltipPosition,
        tooltipPadding: EdgeInsets.fromLTRB(8, 8, 8, 8 + bottomInset),
        child: child,
      );
    },
  );
}
