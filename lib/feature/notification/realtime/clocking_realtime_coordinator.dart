import 'package:note_sondage/feature/notification/realtime/realtime_notification_model.dart';

class ClockingRealtimeCoordinator {
  static const Set<String> _managedEventTypes = {
    'CLOCKING_CLOCKED_IN',
    'CLOCKING_CLOCKED_OUT',
    'CLOCKING_BREAK_STARTED',
    'CLOCKING_BREAK_STOPPED',
    'CLOCKING_RECORD_UPDATED',
    'CLOCKING_RECORD_DECOMMITTED',
    'CLOCKING_RECORD_COMMITTED',
  };

  bool isManagedClockingNotification(RealtimeNotification notification) {
    return notification.sourceService == 'clocking-service' &&
        _managedEventTypes.contains(notification.eventType);
  }

  ClockingRealtimeDecision resolveDecision(
    RealtimeNotification notification, {
    required String currentUserId,
    required String? selectedTeamId,
  }) {
    if (!isManagedClockingNotification(notification)) {
      return ClockingRealtimeDecision.none;
    }

    final eventTeamId = notification.metadata['teamId']?.trim() ?? '';
    final targetUserId = notification.metadata['targetUserId']?.trim() ?? '';
    final refreshCurrentTeam =
        selectedTeamId != null &&
        selectedTeamId.isNotEmpty &&
        eventTeamId.isNotEmpty &&
        selectedTeamId == eventTeamId;
    final refreshCurrentUser =
        currentUserId.isNotEmpty && targetUserId == currentUserId;

    // Clock-in / clock-out events change the todayClocking counter on dashboard
    final refreshDashboard =
        notification.eventType == 'CLOCKING_CLOCKED_IN' ||
        notification.eventType == 'CLOCKING_CLOCKED_OUT';

    return ClockingRealtimeDecision(
      refreshClocking: refreshCurrentTeam || refreshCurrentUser,
      refreshDashboard: refreshDashboard,
    );
  }
}

class ClockingRealtimeDecision {
  final bool refreshClocking;
  final bool refreshDashboard;

  const ClockingRealtimeDecision({
    this.refreshClocking = false,
    this.refreshDashboard = false,
  });

  static const none = ClockingRealtimeDecision();
}
