class NotificationActionIntent {
  const NotificationActionIntent({
    required this.notificationId,
    required this.actionId,
    required this.metadata,
  });

  final String notificationId;
  final String actionId;
  final Map<String, String> metadata;
}
