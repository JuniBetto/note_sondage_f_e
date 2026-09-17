import 'package:flutter/material.dart';
import 'package:note_sondage/theme/extensions/theme_extensions.dart';

/// Wraps a scrollable region and shows a small floating chevron whenever
/// there is content beyond the visible edge — and only then: it stays
/// invisible if everything already fits, and fades out once the user has
/// scrolled far enough to see that edge.
///
/// This relies on [ScrollNotification]/[ScrollMetricsNotification] bubbling
/// up from the scrollable inside [child] (any `ListView`, `SingleChildScrollView`,
/// `CustomScrollView`...), so no extra `ScrollController` wiring is needed at
/// the call site — just wrap the existing scrollable.
class ScrollOverflowHint extends StatefulWidget {
  const ScrollOverflowHint({
    super.key,
    required this.child,
    this.axis = Axis.vertical,
  });

  final Widget child;

  /// Which scroll axis to watch. Must match the wrapped scrollable's own
  /// axis, or metrics never match and no hint is ever shown.
  final Axis axis;

  @override
  State<ScrollOverflowHint> createState() => _ScrollOverflowHintState();
}

class _ScrollOverflowHintState extends State<ScrollOverflowHint> {
  static const double _epsilon = 4;

  bool _hasMoreAtStart = false;
  bool _hasMoreAtEnd = false;

  bool _onNotification(Notification notification) {
    ScrollMetrics? metrics;
    if (notification is ScrollMetricsNotification) {
      metrics = notification.metrics;
    } else if (notification is ScrollNotification) {
      metrics = notification.metrics;
    }
    if (metrics == null || metrics.axis != widget.axis) {
      if (metrics != null) {
        debugPrint(
          '[ScrollOverflowHint] ignored ${notification.runtimeType}: '
          'metrics.axis=${metrics.axis} widget.axis=${widget.axis}',
        );
      }
      return false;
    }
    final hasMoreAtEnd = metrics.maxScrollExtent - metrics.pixels > _epsilon;
    final hasMoreAtStart = metrics.pixels - metrics.minScrollExtent > _epsilon;
    debugPrint(
      '[ScrollOverflowHint] ${notification.runtimeType} pixels=${metrics.pixels} '
      'min=${metrics.minScrollExtent} max=${metrics.maxScrollExtent} '
      'hasMoreAtStart=$hasMoreAtStart hasMoreAtEnd=$hasMoreAtEnd',
    );
    if (hasMoreAtEnd != _hasMoreAtEnd || hasMoreAtStart != _hasMoreAtStart) {
      setState(() {
        _hasMoreAtEnd = hasMoreAtEnd;
        _hasMoreAtStart = hasMoreAtStart;
      });
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final vertical = widget.axis == Axis.vertical;
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: _onNotification,
      child: NotificationListener<ScrollNotification>(
        onNotification: _onNotification,
        child: Stack(
          children: [
            widget.child,
            _Chevron(
              visible: _hasMoreAtStart,
              alignment: vertical ? Alignment.topCenter : Alignment.centerLeft,
              icon: vertical
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_left_rounded,
              margin: vertical
                  ? const EdgeInsets.only(top: 6)
                  : const EdgeInsets.only(left: 6),
            ),
            _Chevron(
              visible: _hasMoreAtEnd,
              alignment: vertical
                  ? Alignment.bottomCenter
                  : Alignment.centerRight,
              icon: vertical
                  ? Icons.keyboard_arrow_down_rounded
                  : Icons.keyboard_arrow_right_rounded,
              margin: vertical
                  ? const EdgeInsets.only(bottom: 6)
                  : const EdgeInsets.only(right: 6),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chevron extends StatelessWidget {
  const _Chevron({
    required this.visible,
    required this.alignment,
    required this.icon,
    required this.margin,
  });

  final bool visible;
  final Alignment alignment;
  final IconData icon;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    return Align(
      alignment: alignment,
      child: IgnorePointer(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: visible ? 1 : 0,
          child: Padding(
            padding: margin,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: (colorScheme.borderColor ?? colorScheme.outline)
                      .withValues(alpha: 0.6),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.14),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: 18,
                color: colorScheme.primaryColor ?? colorScheme.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
