class RealtimeNotification {
  final String notificationId;
  final String eventType;
  final String sourceService;
  final String title;
  final String body;
  final DateTime occurredAt;
  final Map<String, String> metadata;

  const RealtimeNotification({
    required this.notificationId,
    required this.eventType,
    required this.sourceService,
    required this.title,
    required this.body,
    required this.occurredAt,
    required this.metadata,
  });

  factory RealtimeNotification.fromJson(Map<String, dynamic> json) {
    final rawMetadata = json['metadata'];
    final metadata = <String, String>{};
    if (rawMetadata is Map) {
      for (final entry in rawMetadata.entries) {
        if (entry.key != null && entry.value != null) {
          metadata[entry.key.toString()] = entry.value.toString();
        }
      }
    }

    return RealtimeNotification(
      notificationId: json['notificationId']?.toString() ?? '',
      eventType: json['eventType']?.toString() ?? '',
      sourceService: json['sourceService']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      occurredAt: DateTime.tryParse(json['occurredAt']?.toString() ?? '') ??
          DateTime.now(),
      metadata: metadata,
    );
  }
}

