import 'package:flutter/widgets.dart';

/// Exposes the current density scale factor (same value as the selected
/// [TaskTextSize]) to any Task widget below it, so layout dimensions —
/// card padding, row heights, avatar sizes, the calendar's hour-row height,
/// the Gantt row height — shrink/grow together with the text instead of
/// only the text scaling while everything else stays put.
///
/// Falls back to `1.0` (no scaling) when there's no ancestor scope, so
/// widgets that read it stay safe to use outside the Task mobile layout too.
class TaskDensityScope extends InheritedWidget {
  const TaskDensityScope({super.key, required this.scale, required super.child});

  final double scale;

  static double of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<TaskDensityScope>();
    return scope?.scale ?? 1.0;
  }

  @override
  bool updateShouldNotify(TaskDensityScope oldWidget) => oldWidget.scale != scale;
}
