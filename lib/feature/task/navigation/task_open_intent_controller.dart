class TaskOpenIntent {
  const TaskOpenIntent({required this.taskId});

  final String taskId;
}

/// Queues a task to open once [TaskWorkspace] has loaded its task list —
/// mirrors [ShiftOpenIntentController]'s role for shift deep links (e.g. a
/// tap on a "TASK_ASSIGNED" push notification).
class TaskOpenIntentController {
  TaskOpenIntent? _pendingIntent;

  TaskOpenIntent? get pendingIntent => _pendingIntent;

  bool get hasPendingIntent => _pendingIntent != null;

  void queue({required String taskId}) {
    final normalizedTaskId = taskId.trim();
    if (normalizedTaskId.isEmpty) {
      return;
    }
    _pendingIntent = TaskOpenIntent(taskId: normalizedTaskId);
  }

  void clear() {
    _pendingIntent = null;
  }
}
