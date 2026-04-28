import 'package:note_sondage/feature/notification/realtime/realtime_notification_model.dart';

class SondageRealtimeCoordinator {
  static const Set<String> _managedEventTypes = {
    'SONDAGE_DRAFT_CREATED',
    'SONDAGE_DRAFT_UPDATED',
    'SONDAGE_DRAFT_DELETED',
    'SONDAGE_PUBLISHED',
    'SONDAGE_CLOSED',
    'SONDAGE_VOTED',
  };

  bool isManagedSondageNotification(RealtimeNotification notification) {
    return notification.sourceService == 'sondage-service' &&
        _managedEventTypes.contains(notification.eventType);
  }

  SondageRealtimeDecision resolveDecision(RealtimeNotification notification) {
    if (!isManagedSondageNotification(notification)) {
      return SondageRealtimeDecision.none;
    }

    final eventType = notification.eventType;
    final refreshDashboard = eventType == 'SONDAGE_PUBLISHED' ||
        eventType == 'SONDAGE_CLOSED' ||
        eventType == 'SONDAGE_VOTED';

    return SondageRealtimeDecision(
      refreshSondages: true,
      refreshDashboard: refreshDashboard,
    );
  }
}

class SondageRealtimeDecision {
  final bool refreshSondages;
  final bool refreshDashboard;

  const SondageRealtimeDecision({
    this.refreshSondages = false,
    this.refreshDashboard = false,
  });

  static const none = SondageRealtimeDecision();
}
