import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class AnchoredDropdownOverlay extends StatefulWidget {
  const AnchoredDropdownOverlay({
    super.key,
    required this.triggerBuilder,
    required this.overlayBuilder,
    this.offset = const Offset(0, 6),
  });

  final Widget Function(BuildContext context, bool isOpen, VoidCallback toggle)
  triggerBuilder;
  final Widget Function(
    BuildContext context,
    double width,
    double maxHeight,
    VoidCallback close,
  )
  overlayBuilder;
  final Offset offset;

  @override
  State<AnchoredDropdownOverlay> createState() =>
      _AnchoredDropdownOverlayState();
}

class _AnchoredDropdownOverlayState extends State<AnchoredDropdownOverlay>
    with WidgetsBindingObserver {
  static const Duration _kBarrierActivationDelay = Duration(milliseconds: 180);
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _targetKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  OverlayState? _overlayState;
  double _targetWidth = 0;
  double _overlayWidth = 0;
  double _overlayMaxHeight = 320;
  bool _rebuildScheduled = false;
  bool _barrierDismissEnabled = false;
  int _overlaySession = 0;
  double? _lastScreenWidth;

  bool get _isOpen => _overlayEntry != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _overlayState = Overlay.maybeOf(context);
    _lastScreenWidth = MediaQuery.maybeSizeOf(context)?.width;
  }

  @override
  void didChangeMetrics() {
    // Only close the overlay on screen WIDTH changes (e.g. device rotation).
    // Height changes are caused by the software keyboard appearing/disappearing
    // on mobile/simulator and must NOT close the dropdown.
    final view = WidgetsBinding.instance.platformDispatcher.views.firstOrNull;
    if (view != null) {
      final newWidth = view.physicalSize.width / view.devicePixelRatio;
      if (_lastScreenWidth != null && (newWidth - _lastScreenWidth!).abs() < 1) {
        // Only height changed (keyboard) — ignore.
        return;
      }
      _lastScreenWidth = newWidth;
    }
    _removeOverlay();
  }

  @override
  void deactivate() {
    _removeOverlay(rebuild: false);
    super.deactivate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _removeOverlay(rebuild: false);
    super.dispose();
  }

  void _toggleOverlay() {
    if (_isOpen) {
      _removeOverlay();
      return;
    }
    _showOverlay();
  }

  void _showOverlay() {
    _measureTarget();
    final overlay = _overlayState ?? Overlay.maybeOf(context);
    if (overlay == null) {
      return;
    }
    _overlaySession++;
    final session = _overlaySession;
    _barrierDismissEnabled = false;
    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              ignoring: !_barrierDismissEnabled,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _handleBarrierTap,
                child: const SizedBox.expand(),
              ),
            ),
          ),
          CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: widget.offset,
            child: Material(
              color: Colors.transparent,
              child: SizedBox(
                width: _overlayWidth,
                child: widget.overlayBuilder(
                  context,
                  _overlayWidth,
                  _overlayMaxHeight,
                  _removeOverlay,
                ),
              ),
            ),
          ),
        ],
      ),
    );
    overlay.insert(_overlayEntry!);
    Future<void>.delayed(_kBarrierActivationDelay, () {
      if (!mounted || _overlayEntry == null || session != _overlaySession) {
        return;
      }
      _barrierDismissEnabled = true;
      _overlayEntry?.markNeedsBuild();
    });
    _requestRebuild();
  }

  void _removeOverlay({bool rebuild = true}) {
    _overlaySession++;
    _barrierDismissEnabled = false;
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (rebuild) {
      _requestRebuild();
    }
  }

  void _handleBarrierTap() {
    if (!_barrierDismissEnabled) {
      return;
    }
    _removeOverlay();
  }

  void _requestRebuild() {
    if (!mounted) {
      return;
    }

    final schedulerPhase = SchedulerBinding.instance.schedulerPhase;
    final shouldDefer =
        schedulerPhase == SchedulerPhase.transientCallbacks ||
        schedulerPhase == SchedulerPhase.midFrameMicrotasks ||
        schedulerPhase == SchedulerPhase.persistentCallbacks;

    if (!shouldDefer) {
      setState(() {});
      return;
    }

    if (_rebuildScheduled) {
      return;
    }

    _rebuildScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _rebuildScheduled = false;
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  void _measureTarget() {
    final renderBox =
        _targetKey.currentContext?.findRenderObject() as RenderBox?;
    final mediaQuerySize = MediaQuery.maybeSizeOf(context);
    final view = View.of(context);
    final screenSize =
        mediaQuerySize ??
        Size(
          view.physicalSize.width / view.devicePixelRatio,
          view.physicalSize.height / view.devicePixelRatio,
        );
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    const horizontalScreenMargin = 16.0;
    const verticalScreenMargin = 16.0;
    const minOverlayWidth = 340.0;
    const minOverlayHeight = 140.0;
    final maxOverlayWidth = screenWidth - (horizontalScreenMargin * 2);
    if (renderBox == null) {
      _targetWidth = 320;
      _overlayWidth = maxOverlayWidth < minOverlayWidth
          ? maxOverlayWidth
          : minOverlayWidth;
      _overlayMaxHeight = (screenHeight - (verticalScreenMargin * 2)).clamp(
        minOverlayHeight,
        360.0,
      );
      return;
    }
    _targetWidth = renderBox.size.width;
    final desiredWidth = _targetWidth < minOverlayWidth
        ? minOverlayWidth
        : _targetWidth;
    _overlayWidth = desiredWidth.clamp(220.0, maxOverlayWidth);
    final targetOrigin = renderBox.localToGlobal(Offset.zero);
    final targetBottom =
        targetOrigin.dy + renderBox.size.height + widget.offset.dy;
    final availableHeightBelow =
        screenHeight - targetBottom - verticalScreenMargin;
    _overlayMaxHeight = availableHeightBelow.clamp(minOverlayHeight, 360.0);
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: KeyedSubtree(
        key: _targetKey,
        child: widget.triggerBuilder(context, _isOpen, _toggleOverlay),
      ),
    );
  }
}
