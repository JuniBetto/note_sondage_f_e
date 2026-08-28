enum ShiftTextSize { tiny, extraSmall, compact, small, medium, large }

extension ShiftTextSizeWireValue on ShiftTextSize {
  String get wireValue => switch (this) {
    ShiftTextSize.tiny => 'tiny',
    ShiftTextSize.extraSmall => 'extra_small',
    ShiftTextSize.compact => 'compact',
    ShiftTextSize.small => 'small',
    ShiftTextSize.medium => 'medium',
    ShiftTextSize.large => 'large',
  };

  /// Uniform text-scale multiplier applied via [MediaQueryData.textScaler]
  /// so every text style across the Shift mobile views shrinks/grows
  /// together, without hand-tuning each widget's font size.
  double get scaleFactor => switch (this) {
    ShiftTextSize.tiny => 0.55,
    ShiftTextSize.extraSmall => 0.65,
    ShiftTextSize.compact => 0.75,
    ShiftTextSize.small => 0.85,
    ShiftTextSize.medium => 1.0,
    ShiftTextSize.large => 1.15,
  };

  static ShiftTextSize fromWireValue(String? raw) {
    return switch (raw) {
      'tiny' => ShiftTextSize.tiny,
      'extra_small' => ShiftTextSize.extraSmall,
      'compact' => ShiftTextSize.compact,
      'small' => ShiftTextSize.small,
      'large' => ShiftTextSize.large,
      _ => ShiftTextSize.medium,
    };
  }
}
