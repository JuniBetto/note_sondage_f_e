import 'package:flutter/material.dart';
import 'package:note_sondage/feature/task/ui/task_workspace.dart';

class TaskMobileWidget extends StatelessWidget {
  const TaskMobileWidget({
    super.key,
    this.initialTeamId,
    this.isActive = true,
    this.isTabTransitioning = false,
  });

  final String? initialTeamId;

  /// Whether the Task sub-tab is the one currently selected in the parent
  /// [TabBarView] (which builds all four tabs eagerly, so this widget is
  /// mounted well before it is actually visible).
  final bool isActive;

  /// Whether the parent tab controller is still animating between tabs —
  /// the auto-tutorial waits for the swipe to settle before starting, see
  /// [TaskWorkspace].
  final bool isTabTransitioning;

  @override
  Widget build(BuildContext context) {
    return TaskWorkspace(
      initialTeamId: initialTeamId,
      embedded: true,
      isActive: isActive,
      isTabTransitioning: isTabTransitioning,
    );
  }
}
