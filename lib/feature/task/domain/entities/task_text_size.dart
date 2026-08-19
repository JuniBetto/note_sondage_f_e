enum TaskTextSize { tiny, extraSmall, compact, small, medium, large }

extension TaskTextSizeWireValue on TaskTextSize {
  String get wireValue => switch (this) {
    TaskTextSize.tiny => 'tiny',
    TaskTextSize.extraSmall => 'extra_small',
    TaskTextSize.compact => 'compact',
    TaskTextSize.small => 'small',
    TaskTextSize.medium => 'medium',
    TaskTextSize.large => 'large',
  };

  /// Uniform text-scale multiplier applied via [MediaQueryData.textScaler]
  /// so every text style across the Task mobile views shrinks/grows
  /// together, without hand-tuning each widget's font size.
  double get scaleFactor => switch (this) {
    TaskTextSize.tiny => 0.55,
    TaskTextSize.extraSmall => 0.65,
    TaskTextSize.compact => 0.75,
    TaskTextSize.small => 0.85,
    TaskTextSize.medium => 1.0,
    TaskTextSize.large => 1.15,
  };

  static TaskTextSize fromWireValue(String? raw) {
    return switch (raw) {
      'tiny' => TaskTextSize.tiny,
      'extra_small' => TaskTextSize.extraSmall,
      'compact' => TaskTextSize.compact,
      'small' => TaskTextSize.small,
      'large' => TaskTextSize.large,
      _ => TaskTextSize.medium,
    };
  }
}
