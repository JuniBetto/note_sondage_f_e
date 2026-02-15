import 'package:flutter/material.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';

class ActionOnUser extends StatelessWidget {
  final double borderRadius;
  final double borderWidth;
  final EdgeInsets padding;
  final double iconSize;
  final IconData icon;
  final Color? color;
  final void Function()? onTap;

  const ActionOnUser({
    super.key,
    this.borderRadius = 8.0,
    this.borderWidth = 2.0,
    this.padding = const EdgeInsets.all(4.0),
    this.iconSize = 14.0,
    this.icon = Icons.edit,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color:
              color?.withOpacity(0.2) ??
              colorScheme.selectionColor!.withOpacity(0.2),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: color ?? colorScheme.cursorColor!,
            width: borderWidth,
          ),
        ),
        child: Padding(
          padding: padding,
          child: Icon(
            icon,
            size: iconSize,
            color: color ?? colorScheme.cursorColor!,
          ),
        ),
      ),
    );
  }
}
