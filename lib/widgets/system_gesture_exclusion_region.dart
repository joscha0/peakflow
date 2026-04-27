import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SystemGestureExclusionRegion extends StatefulWidget {
  final Widget child;

  const SystemGestureExclusionRegion({super.key, required this.child});

  @override
  State<SystemGestureExclusionRegion> createState() =>
      _SystemGestureExclusionRegionState();
}

class _SystemGestureExclusionRegionState
    extends State<SystemGestureExclusionRegion>
    with WidgetsBindingObserver {
  static const MethodChannel _channel = MethodChannel(
    'peakflow/system_gesture_exclusion',
  );

  Rect? _lastRect;
  bool _updateScheduled = false;

  bool get _isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduleRectUpdate();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scheduleRectUpdate();
  }

  @override
  void didUpdateWidget(covariant SystemGestureExclusionRegion oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleRectUpdate();
  }

  @override
  void didChangeMetrics() {
    _scheduleRectUpdate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_isSupported) {
      _channel.invokeMethod<void>('clear').catchError((_) {});
    }
    super.dispose();
  }

  void _scheduleRectUpdate() {
    if (!_isSupported || _updateScheduled) {
      return;
    }

    _updateScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateScheduled = false;
      if (!mounted) {
        return;
      }
      _updateRect();
    });
  }

  Future<void> _updateRect() async {
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) {
      return;
    }

    final topLeft = renderObject.localToGlobal(Offset.zero);
    final size = renderObject.size;
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    final rect = Rect.fromLTWH(
      topLeft.dx * pixelRatio,
      topLeft.dy * pixelRatio,
      size.width * pixelRatio,
      size.height * pixelRatio,
    );

    if (_lastRect == rect) {
      return;
    }

    _lastRect = rect;
    await _channel
        .invokeMethod<void>('setRects', [
          {
            'left': rect.left.round(),
            'top': rect.top.round(),
            'right': rect.right.round(),
            'bottom': rect.bottom.round(),
          },
        ])
        .catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    _scheduleRectUpdate();
    return widget.child;
  }
}
