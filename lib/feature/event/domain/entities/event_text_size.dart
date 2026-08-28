enum EventTextSize { tiny, extraSmall, compact, small, medium, large }

extension EventTextSizeWireValue on EventTextSize {
  String get wireValue => switch (this) {
    EventTextSize.tiny => 'tiny',
    EventTextSize.extraSmall => 'extra_small',
    EventTextSize.compact => 'compact',
    EventTextSize.small => 'small',
    EventTextSize.medium => 'medium',
    EventTextSize.large => 'large',
  };

  /// Uniform text-scale multiplier applied via [MediaQueryData.textScaler]
  /// so every text style across the Event mobile views shrinks/grows
  /// together, without hand-tuning each widget's font size.
  double get scaleFactor => switch (this) {
    EventTextSize.tiny => 0.55,
    EventTextSize.extraSmall => 0.65,
    EventTextSize.compact => 0.75,
    EventTextSize.small => 0.85,
    EventTextSize.medium => 1.0,
    EventTextSize.large => 1.15,
  };

  static EventTextSize fromWireValue(String? raw) {
    return switch (raw) {
      'tiny' => EventTextSize.tiny,
      'extra_small' => EventTextSize.extraSmall,
      'compact' => EventTextSize.compact,
      'small' => EventTextSize.small,
      'large' => EventTextSize.large,
      _ => EventTextSize.medium,
    };
  }
}
