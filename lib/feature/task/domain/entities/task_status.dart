enum TaskStatus { open, inProgress, blocked, done, canceled }

extension TaskStatusWireValue on TaskStatus {
  String get wireValue => switch (this) {
    TaskStatus.open => 'open',
    TaskStatus.inProgress => 'in_progress',
    TaskStatus.blocked => 'blocked',
    TaskStatus.done => 'done',
    TaskStatus.canceled => 'canceled',
  };

  static TaskStatus fromWireValue(String? raw) {
    return switch ((raw ?? '').trim().toLowerCase()) {
      'in_progress' => TaskStatus.inProgress,
      'blocked' => TaskStatus.blocked,
      'done' => TaskStatus.done,
      'canceled' => TaskStatus.canceled,
      _ => TaskStatus.open,
    };
  }
}
