import 'package:flutter/material.dart';
import 'package:note_sondage/feature/task/ui/task_workspace.dart';

class TaskWebPage extends StatelessWidget {
  const TaskWebPage({super.key, this.initialTeamId});

  final String? initialTeamId;

  @override
  Widget build(BuildContext context) {
    return TaskWorkspace(initialTeamId: initialTeamId);
  }
}
