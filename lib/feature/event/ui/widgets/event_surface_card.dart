import 'package:flutter/material.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';

class EventSurfaceCard extends StatelessWidget {
  const EventSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 18,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: colorScheme.bgNavbarSurface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: colorScheme.borderColor ?? Colors.transparent,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}
