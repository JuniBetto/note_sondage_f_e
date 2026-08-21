import 'package:flutter/material.dart';
import 'package:note_sondage/feature/event/ui/event_workspace.dart';

class EventMobileWidget extends StatelessWidget {
  const EventMobileWidget({super.key, this.initialTeamId, this.initialEventId});

  final String? initialTeamId;
  final String? initialEventId;

  @override
  Widget build(BuildContext context) {
    return EventWorkspace(
      initialTeamId: initialTeamId,
      initialEventId: initialEventId,
      embedded: true,
    );
  }
}
