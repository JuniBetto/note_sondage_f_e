import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_sondage/feature/event/ui/event_workspace.dart';
import 'package:note_sondage/ui/bloc/navigation_bloc/navigation_bloc.dart';

// Deve restare allineato all'indice della scheda Event nell'IndexedStack di
// MainWeb (vedi _pathToNavIndex in routes.dart e main_web.dart).
const int _eventNavIndex = 8;

class EventWebPage extends StatelessWidget {
  const EventWebPage({super.key, this.initialTeamId, this.initialEventId});

  final String? initialTeamId;
  final String? initialEventId;

  @override
  Widget build(BuildContext context) {
    // La pagina vive dentro l'IndexedStack di MainWeb ed è quindi montata
    // anche quando un'altra scheda è quella visibile: il tutorial dentro
    // EventWorkspace deve sapere se la scheda Event è davvero quella
    // attiva prima di potersi avviare automaticamente.
    final isEventTabActive =
        context.watch<NavigationBloc>().state == _eventNavIndex;
    return EventWorkspace(
      initialTeamId: initialTeamId,
      initialEventId: initialEventId,
      isActive: isEventTabActive,
    );
  }
}
