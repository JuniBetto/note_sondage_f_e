enum TaskPriority { low, medium, high }

extension TaskPriorityWireValue on TaskPriority {
  String get wireValue => switch (this) {
    TaskPriority.low => 'low',
    TaskPriority.medium => 'medium',
    TaskPriority.high => 'high',
  };

  static TaskPriority fromWireValue(String? raw) {
    return switch ((raw ?? '').trim().toLowerCase()) {
      'low' => TaskPriority.low,
      'high' => TaskPriority.high,
      _ => TaskPriority.medium,
    };
  }
}
