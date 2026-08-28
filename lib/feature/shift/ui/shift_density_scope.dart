import 'package:flutter/widgets.dart';

/// Exposes the current density scale factor (same value as the selected
/// `ShiftTextSize`) to any Shift widget below it, so layout dimensions can
/// shrink/grow together with the text instead of only the text scaling
/// while everything else stays put.
///
/// Falls back to `1.0` (no scaling) when there's no ancestor scope, so
/// widgets that read it stay safe to use outside the Shift mobile layout too.
class ShiftDensityScope extends InheritedWidget {
  const ShiftDensityScope({
    super.key,
    required this.scale,
    required super.child,
  });

  final double scale;

  static double of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<ShiftDensityScope>();
    return scope?.scale ?? 1.0;
  }

  @override
  bool updateShouldNotify(ShiftDensityScope oldWidget) =>
      oldWidget.scale != scale;
}
