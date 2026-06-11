import 'package:flutter/widgets.dart' as widgets;

class AspectRatio extends widgets.StatelessWidget {
  final widgets.Widget child;
  final double aspectRatio;
  final widgets.BorderRadius borderRadius;
  final widgets.Clip clipBehavior;

  const AspectRatio({
    super.key,
    required this.child,
    this.aspectRatio = 16 / 9,
    this.borderRadius = const widgets.BorderRadius.all(
      widgets.Radius.circular(16),
    ),
    this.clipBehavior = widgets.Clip.antiAlias,
  });

  @override
  widgets.Widget build(widgets.BuildContext context) {
    return widgets.AspectRatio(
      aspectRatio: aspectRatio,
      child: widgets.ClipRRect(
        borderRadius: borderRadius,
        clipBehavior: clipBehavior,
        child: child,
      ),
    );
  }
}
