import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
export 'package:showcaseview/showcaseview.dart';

bool get isInspectorSelectionActive {
  if (!kDebugMode) {
    return false;
  }

  final binding = WidgetsBinding.instance;
  return binding.debugWidgetInspectorSelectionOnTapEnabled.value;
}
