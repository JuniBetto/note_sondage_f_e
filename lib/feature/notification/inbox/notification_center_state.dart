part of 'notification_center_cubit.dart';

enum NotificationCenterStatus { initial, loading, loaded, error }

class NotificationCenterState extends Equatable {
  const NotificationCenterState({
    this.status = NotificationCenterStatus.initial,
    this.notifications = const [],
    this.seenNotificationIds = const {},
    this.dismissedNotificationIds = const {},
    this.processingNotificationIds = const {},
    this.completedActionNotificationIds = const {},
    this.errorMessage,
  });

  final NotificationCenterStatus status;
  final List<NotificationCenterItem> notifications;
  final Set<String> seenNotificationIds;
  final Set<String> dismissedNotificationIds;
  final Set<String> processingNotificationIds;
  final Set<String> completedActionNotificationIds;
  final String? errorMessage;

  List<NotificationCenterItem> pendingFor(String currentUserId) {
    return notifications.where((item) {
      if (dismissedNotificationIds.contains(item.notificationId)) {
        return false;
      }
      final seen = seenNotificationIds.contains(item.notificationId);
      final completed = completedActionNotificationIds.contains(
        item.notificationId,
      );
      if (seen || completed) {
        return false;
      }
      return true;
    }).toList();
  }

  NotificationCenterState copyWith({
    NotificationCenterStatus? status,
    List<NotificationCenterItem>? notifications,
    Set<String>? seenNotificationIds,
    Set<String>? dismissedNotificationIds,
    Set<String>? processingNotificationIds,
    Set<String>? completedActionNotificationIds,
    String? errorMessage,
  }) {
    return NotificationCenterState(
      status: status ?? this.status,
      notifications: notifications ?? this.notifications,
      seenNotificationIds: seenNotificationIds ?? this.seenNotificationIds,
      dismissedNotificationIds:
          dismissedNotificationIds ?? this.dismissedNotificationIds,
      processingNotificationIds:
          processingNotificationIds ?? this.processingNotificationIds,
      completedActionNotificationIds:
          completedActionNotificationIds ??
          this.completedActionNotificationIds,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    notifications,
    seenNotificationIds,
    dismissedNotificationIds,
    processingNotificationIds,
    completedActionNotificationIds,
    errorMessage,
  ];
}
