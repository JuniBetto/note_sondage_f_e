class EventOpenIntent {
  const EventOpenIntent({required this.eventId});

  final String eventId;
}

/// Queues an event to open once [EventWorkspace] is ready, mirroring the
/// task/shift deep-link flow used by notifications and URL navigation.
class EventOpenIntentController {
  EventOpenIntent? _pendingIntent;

  EventOpenIntent? get pendingIntent => _pendingIntent;

  bool get hasPendingIntent => _pendingIntent != null;

  void queue({required String eventId}) {
    final normalizedEventId = eventId.trim();
    if (normalizedEventId.isEmpty) {
      return;
    }
    _pendingIntent = EventOpenIntent(eventId: normalizedEventId);
  }

  void clear() {
    _pendingIntent = null;
  }
}
