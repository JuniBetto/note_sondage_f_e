import 'package:note_sondage/feature/notification/realtime/realtime_notification_model.dart';

/// Coordinator per gli eventi realtime del servizio event.
/// Segue lo stesso pattern di [TaskRealtimeCoordinator]: qualunque evento
/// gestito comporta un refresh della lista, lasciando al fetch successivo
/// (già filtrato per team corrente) il compito di scartare ciò che non
/// riguarda la vista attualmente aperta.
class EventRealtimeCoordinator {
  static const Set<String> _managedEventTypes = {
    'EVENT_CREATED',
    'EVENT_UPDATED',
    'EVENT_DELETED',
  };

  bool isManagedEventNotification(RealtimeNotification notification) {
    return notification.sourceService == 'event-service' &&
        _managedEventTypes.contains(notification.eventType);
  }

  EventRealtimeDecision resolveDecision(RealtimeNotification notification) {
    if (!isManagedEventNotification(notification)) {
      return EventRealtimeDecision.none;
    }
    return const EventRealtimeDecision(refreshEvents: true);
  }
}

class EventRealtimeDecision {
  final bool refreshEvents;

  const EventRealtimeDecision({this.refreshEvents = false});

  static const none = EventRealtimeDecision();
}
