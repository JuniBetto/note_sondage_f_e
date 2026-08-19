import 'package:note_sondage/feature/notification/realtime/realtime_notification_model.dart';

/// Coordinator per gli eventi realtime del servizio task.
/// Segue lo stesso pattern di [ShiftRealtimeCoordinator]: qualunque evento
/// gestito comporta un refresh della lista, lasciando al fetch successivo
/// (già filtrato per team/utente corrente) il compito di scartare ciò che
/// non riguarda la vista attualmente aperta.
class TaskRealtimeCoordinator {
  static const Set<String> _managedEventTypes = {
    'TASK_ASSIGNED',
    'TASK_UPDATED',
  };

  bool isManagedTaskNotification(RealtimeNotification notification) {
    return notification.sourceService == 'task-service' &&
        _managedEventTypes.contains(notification.eventType);
  }

  TaskRealtimeDecision resolveDecision(RealtimeNotification notification) {
    if (!isManagedTaskNotification(notification)) {
      return TaskRealtimeDecision.none;
    }
    return const TaskRealtimeDecision(refreshTasks: true);
  }
}

class TaskRealtimeDecision {
  final bool refreshTasks;

  const TaskRealtimeDecision({this.refreshTasks = false});

  static const none = TaskRealtimeDecision();
}
