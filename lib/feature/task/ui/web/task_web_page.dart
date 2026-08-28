import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_sondage/feature/task/ui/task_workspace.dart';
import 'package:note_sondage/ui/bloc/navigation_bloc/navigation_bloc.dart';

// Deve restare allineato all'indice della scheda Task nell'IndexedStack di
// MainWeb (vedi _pathToNavIndex in routes.dart e main_web.dart).
const int _taskNavIndex = 6;

class TaskWebPage extends StatelessWidget {
  const TaskWebPage({super.key, this.initialTeamId});

  final String? initialTeamId;

  @override
  Widget build(BuildContext context) {
    // La pagina vive dentro l'IndexedStack di MainWeb ed è quindi montata
    // anche quando un'altra scheda è quella visibile: il tutorial dentro
    // TaskWorkspace deve sapere se la scheda Task è davvero quella attiva
    // prima di potersi avviare automaticamente.
    final isTaskTabActive =
        context.watch<NavigationBloc>().state == _taskNavIndex;
    return TaskWorkspace(
      initialTeamId: initialTeamId,
      isActive: isTaskTabActive,
    );
  }
}
