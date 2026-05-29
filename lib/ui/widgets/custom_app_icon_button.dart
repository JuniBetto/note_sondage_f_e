import 'package:flutter/material.dart';

enum CustomAppIconButtonType { standard, filled, filledTonal, outlined }

class CustomAppIconButton extends StatelessWidget {
  const CustomAppIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.tooltip,
    this.type = CustomAppIconButtonType.standard,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.visualDensity,
    this.style,
  });

  final VoidCallback? onPressed;
  final Widget icon;
  final String? tooltip;
  final CustomAppIconButtonType type;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;
  final VisualDensity? visualDensity;
  final ButtonStyle? style;

  @override
  Widget build(BuildContext context) {
    final button = switch (type) {
      CustomAppIconButtonType.standard => IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        visualDensity: visualDensity,
        style: style,
        color: foregroundColor,
        icon: icon,
      ),
      CustomAppIconButtonType.filled => IconButton.filled(
        onPressed: onPressed,
        tooltip: tooltip,
        visualDensity: visualDensity,
        style: style,
        color: foregroundColor,
        icon: icon,
      ),
      CustomAppIconButtonType.filledTonal => IconButton.filledTonal(
        onPressed: onPressed,
        tooltip: tooltip,
        visualDensity: visualDensity,
        style: style,
        color: foregroundColor,
        icon: icon,
      ),
      CustomAppIconButtonType.outlined => IconButton.outlined(
        onPressed: onPressed,
        tooltip: tooltip,
        visualDensity: visualDensity,
        style:
            style ??
            IconButton.styleFrom(
              side: borderColor != null
                  ? BorderSide(color: borderColor!)
                  : null,
              backgroundColor: backgroundColor,
              foregroundColor: foregroundColor,
            ),
        color: foregroundColor,
        icon: icon,
      ),
    };

    return button;
  }
}
