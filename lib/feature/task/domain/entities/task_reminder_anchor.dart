enum TaskReminderAnchor { dueAt, startAt }

extension TaskReminderAnchorWireValue on TaskReminderAnchor {
  String get wireValue => switch (this) {
    TaskReminderAnchor.dueAt => 'due_at',
    TaskReminderAnchor.startAt => 'start_at',
  };

  static TaskReminderAnchor fromWireValue(String? raw) {
    return switch ((raw ?? '').trim().toLowerCase()) {
      'start_at' => TaskReminderAnchor.startAt,
      _ => TaskReminderAnchor.dueAt,
    };
  }
}
