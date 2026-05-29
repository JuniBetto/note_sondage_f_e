import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SubmitOnEnterScope extends StatelessWidget {
  const SubmitOnEnterScope({
    super.key,
    required this.child,
    required this.onSubmit,
    this.enabled = true,
    this.ignoreWhenMultilineFocused = true,
  });

  final Widget child;
  final VoidCallback? onSubmit;
  final bool enabled;
  final bool ignoreWhenMultilineFocused;

  @override
  Widget build(BuildContext context) {
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: (_, event) {
        if (!enabled || onSubmit == null || event is! KeyDownEvent) {
          return KeyEventResult.ignored;
        }

        final key = event.logicalKey;
        if (key != LogicalKeyboardKey.enter &&
            key != LogicalKeyboardKey.numpadEnter) {
          return KeyEventResult.ignored;
        }

        final keyboard = HardwareKeyboard.instance;
        if (keyboard.isAltPressed ||
            keyboard.isControlPressed ||
            keyboard.isMetaPressed ||
            keyboard.isShiftPressed) {
          return KeyEventResult.ignored;
        }

        if (ignoreWhenMultilineFocused &&
            _hasMultilineEditableFocus(FocusManager.instance.primaryFocus)) {
          return KeyEventResult.ignored;
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          onSubmit?.call();
        });
        return KeyEventResult.handled;
      },
      child: child,
    );
  }

  static bool _hasMultilineEditableFocus(FocusNode? focusNode) {
    final focusContext = focusNode?.context;
    if (focusContext == null) {
      return false;
    }

    final widget = focusContext.widget;
    if (widget is EditableText) {
      return widget.maxLines == null || widget.maxLines! > 1;
    }

    final editable = focusContext.findAncestorWidgetOfExactType<EditableText>();
    if (editable == null) {
      return false;
    }

    return editable.maxLines == null || editable.maxLines! > 1;
  }
}
