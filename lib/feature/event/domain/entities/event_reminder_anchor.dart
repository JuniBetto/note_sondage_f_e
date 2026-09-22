enum EventReminderAnchor { startsAt, endsAt }

extension EventReminderAnchorWireValue on EventReminderAnchor {
  String get wireValue => switch (this) {
    EventReminderAnchor.startsAt => 'starts_at',
    EventReminderAnchor.endsAt => 'ends_at',
  };

  static EventReminderAnchor fromWireValue(String? raw) {
    return switch ((raw ?? '').trim().toLowerCase()) {
      'ends_at' => EventReminderAnchor.endsAt,
      _ => EventReminderAnchor.startsAt,
    };
  }
}
