import 'package:note_sondage/feature/notification/realtime/realtime_notification_model.dart';

/// Coordinator per gli eventi realtime del servizio turni.
/// Segue lo stesso pattern di [ClockingRealtimeCoordinator].
class ShiftRealtimeCoordinator {
  static const Set<String> _managedEventTypes = {
    'SHIFT_ASSIGNED',
    'SHIFT_UPDATED',
    'SHIFT_DELETED',
    'SHIFT_ALARM_REMINDER',
  };

  bool isManagedShiftNotification(RealtimeNotification notification) {
    return notification.sourceService == 'shift-service' &&
        _managedEventTypes.contains(notification.eventType);
  }

  ShiftRealtimeDecision resolveDecision(
    RealtimeNotification notification, {
    required String currentUserId,
  }) {
    if (!isManagedShiftNotification(notification)) {
      return ShiftRealtimeDecision.none;
    }

    final isAlarm = notification.eventType == 'SHIFT_ALARM_REMINDER';
    final shouldRefresh = notification.metadata['refresh'] == 'shift' || !isAlarm;

    return ShiftRealtimeDecision(
      refreshCalendar: shouldRefresh,
      showAlarmBanner: currentUserId.isNotEmpty && isAlarm,
      alarmShiftDate: isAlarm ? notification.metadata['shiftDate'] ?? '' : null,
      alarmProfileName: isAlarm
          ? notification.metadata['profileName'] ?? ''
          : null,
      alarmMinutesBefore: isAlarm
          ? int.tryParse(notification.metadata['minutesBefore'] ?? '')
          : null,
    );
  }
}

class ShiftRealtimeDecision {
  final bool refreshCalendar;
  final bool showAlarmBanner;
  final String? alarmShiftDate;
  final String? alarmProfileName;
  final int? alarmMinutesBefore;

  const ShiftRealtimeDecision({
    this.refreshCalendar = false,
    this.showAlarmBanner = false,
    this.alarmShiftDate,
    this.alarmProfileName,
    this.alarmMinutesBefore,
  });

  static const none = ShiftRealtimeDecision();
}
