import 'package:flutter/material.dart';
import 'package:note_sondage/feature/event/ui/event_workspace.dart';

class EventMobileWidget extends StatelessWidget {
  const EventMobileWidget({
    super.key,
    this.initialTeamId,
    this.initialEventId,
    this.isActive = true,
    this.isTabTransitioning = false,
  });

  final String? initialTeamId;
  final String? initialEventId;

  /// Whether the Event sub-tab is the one currently selected in the parent
  /// [TabBarView] (which builds all four tabs eagerly, so this widget is
  /// mounted well before it is actually visible).
  final bool isActive;

  /// Whether the parent tab controller is still animating between tabs —
  /// the auto-tutorial waits for the swipe to settle before starting, see
  /// [EventWorkspace].
  final bool isTabTransitioning;

  @override
  Widget build(BuildContext context) {
    return EventWorkspace(
      initialTeamId: initialTeamId,
      initialEventId: initialEventId,
      embedded: true,
      isActive: isActive,
      isTabTransitioning: isTabTransitioning,
    );
  }
}
