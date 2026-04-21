import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PeakFlowValueSelector extends StatefulWidget {
  const PeakFlowValueSelector({
    super.key,
    required this.value,
    required this.maxVolume,
    required this.onChanged,
    this.onDraggingChanged,
  });

  final double value;
  final int maxVolume;
  final ValueChanged<double> onChanged;
  final ValueChanged<bool>? onDraggingChanged;

  @override
  State<PeakFlowValueSelector> createState() => _PeakFlowValueSelectorState();
}

class _PeakFlowValueSelectorState extends State<PeakFlowValueSelector> {
  final valueController = TextEditingController();
  bool isDragging = false;

  @override
  void initState() {
    super.initState();
    _syncValueText(widget.value.round());
  }

  @override
  void didUpdateWidget(covariant PeakFlowValueSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value.round() != widget.value.round()) {
      _syncValueText(widget.value.round());
    }
  }

  @override
  void dispose() {
    valueController.dispose();
    super.dispose();
  }

  void _syncValueText(int value) {
    final text = value.toString();
    if (valueController.text == text) {
      return;
    }

    valueController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  double _normalizeValue(double value) {
    final snappedValue =
        ((value.clamp(0, widget.maxVolume.toDouble())) / 10).round() * 10;
    return snappedValue
        .toDouble()
        .clamp(0, widget.maxVolume.toDouble())
        .toDouble();
  }

  void _updateValue(double value) {
    final normalizedValue = _normalizeValue(value);
    widget.onChanged(normalizedValue);
    _syncValueText(normalizedValue.round());
  }

  bool _isPositionOnSelectorRing(Offset localPosition, Size size) {
    final strokeWidth = size.width * 0.09;
    final center = Offset(size.width / 2, size.height * 0.94);
    final radius = (size.width - strokeWidth) / 2.4;
    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;
    final distance = math.sqrt((dx * dx) + (dy * dy));

    return distance >= radius - strokeWidth && distance <= radius + strokeWidth;
  }

  void _updateValueFromPosition(Offset localPosition, Size size) {
    if (!_isPositionOnSelectorRing(localPosition, size)) {
      return;
    }

    final center = Offset(size.width / 2, size.height * 0.94);
    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;
    var angle = math.atan2(dy, dx);
    if (angle < 0) {
      angle += math.pi * 2;
    }

    if (angle < math.pi) {
      angle = localPosition.dx < center.dx ? math.pi : math.pi * 2;
    }

    final progress = (angle - math.pi) / math.pi;
    _updateValue(progress * widget.maxVolume);
  }

  void _handleValueTextChanged(String value) {
    if (value.isEmpty) {
      return;
    }

    final parsedValue = int.tryParse(value);
    if (parsedValue == null) {
      return;
    }

    final clampedValue = parsedValue.clamp(0, widget.maxVolume);
    widget.onChanged(clampedValue.toDouble());

    if (clampedValue != parsedValue) {
      _syncValueText(clampedValue);
    }
  }

  void _normalizeTypedValue() {
    final parsedValue = int.tryParse(valueController.text) ?? 0;
    _updateValue(parsedValue.toDouble());
  }

  void _setDragging(bool value) {
    if (isDragging == value) {
      return;
    }
    setState(() {
      isDragging = value;
    });
    widget.onDraggingChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = widget.maxVolume == 0
        ? 0.0
        : widget.value / widget.maxVolume;

    return LayoutBuilder(
      builder: (context, constraints) {
        final selectorSize = math.min(constraints.maxWidth, 320.0);
        final selectorHeight = selectorSize * 0.6;
        final selectorCanvasSize = Size(selectorSize, selectorHeight);

        return Center(
          child: SizedBox(
            width: selectorSize,
            child: Stack(
              children: [
                Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: (event) {
                    if (!_isPositionOnSelectorRing(
                      event.localPosition,
                      selectorCanvasSize,
                    )) {
                      return;
                    }

                    _setDragging(true);
                    _updateValueFromPosition(
                      event.localPosition,
                      selectorCanvasSize,
                    );
                  },
                  onPointerMove: (event) {
                    if (!isDragging) {
                      return;
                    }

                    _updateValueFromPosition(
                      event.localPosition,
                      selectorCanvasSize,
                    );
                  },
                  onPointerUp: (_) {
                    _setDragging(false);
                  },
                  onPointerCancel: (_) {
                    _setDragging(false);
                  },
                  child: SizedBox(
                    width: selectorSize,
                    height: selectorHeight,
                    child: CustomPaint(
                      size: selectorCanvasSize,
                      painter: _HalfCircleSelectorPainter(
                        maxVolume: widget.maxVolume,
                        progress: progress,
                        activeColor: theme.colorScheme.primary,
                        trackColor: theme.dividerColor.withValues(alpha: 0.18),
                        tickColor: theme.dividerColor.withValues(alpha: 0.45),
                        textColor: theme.colorScheme.onSurface.withValues(
                          alpha: 0.78,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Align(
                    alignment: const Alignment(0, 1),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 140,
                          child: TextFormField(
                            controller: valueController,
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9]'),
                              ),
                            ],
                            style: theme.textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            decoration: const InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: _handleValueTextChanged,
                            onTapOutside: (_) {
                              FocusScope.of(context).unfocus();
                              _normalizeTypedValue();
                            },
                            onFieldSubmitted: (_) {
                              _normalizeTypedValue();
                            },
                          ),
                        ),
                        Text(
                          'L/min',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Drag the arc or type a value',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.62,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HalfCircleSelectorPainter extends CustomPainter {
  const _HalfCircleSelectorPainter({
    required this.maxVolume,
    required this.progress,
    required this.activeColor,
    required this.trackColor,
    required this.tickColor,
    required this.textColor,
  });

  final int maxVolume;
  final double progress;
  final Color activeColor;
  final Color trackColor;
  final Color tickColor;
  final Color textColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final strokeWidth = size.width * 0.09;
    final centerPoint = Offset(center.dx, size.height * 0.94);
    final radius = (size.width - strokeWidth) / 2.4;
    final rect = Rect.fromCircle(center: centerPoint, radius: radius);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final tickPaint = Paint()
      ..color = tickColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final labelStyle = TextStyle(
      color: textColor,
      fontSize: 11,
      fontWeight: FontWeight.w600,
    );

    canvas.drawArc(rect, math.pi, math.pi, false, trackPaint);
    canvas.drawArc(rect, math.pi, math.pi * progress, false, activePaint);

    for (var i = 0; i <= 12; i++) {
      final angle = math.pi + (i / 12) * math.pi;
      final start = Offset(
        centerPoint.dx + math.cos(angle) * (radius + strokeWidth * 0.72),
        centerPoint.dy + math.sin(angle) * (radius + strokeWidth * 0.72),
      );
      final end = Offset(
        centerPoint.dx + math.cos(angle) * (radius + strokeWidth * 0.98),
        centerPoint.dy + math.sin(angle) * (radius + strokeWidth * 0.98),
      );
      canvas.drawLine(start, end, tickPaint);

      if (i.isEven) {
        final labelValue = (((maxVolume / 12) * i) / 10).round() * 10;
        final textPainter = TextPainter(
          text: TextSpan(text: labelValue.toString(), style: labelStyle),
          textDirection: ui.TextDirection.ltr,
        )..layout();

        final labelOffset = Offset(
          centerPoint.dx +
              math.cos(angle) * (radius + strokeWidth * 1.85) -
              (textPainter.width / 2),
          centerPoint.dy +
              math.sin(angle) * (radius + strokeWidth * 1.85) -
              (textPainter.height / 2),
        );
        textPainter.paint(canvas, labelOffset);
      }
    }

    final knobAngle = math.pi + (math.pi * progress);
    final knobCenter = Offset(
      centerPoint.dx + math.cos(knobAngle) * radius,
      centerPoint.dy + math.sin(knobAngle) * radius,
    );

    canvas.drawCircle(
      knobCenter,
      strokeWidth * 0.44,
      Paint()..color = activeColor,
    );
    canvas.drawCircle(
      knobCenter,
      strokeWidth * 0.2,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _HalfCircleSelectorPainter oldDelegate) {
    return oldDelegate.maxVolume != maxVolume ||
        oldDelegate.textColor != textColor ||
        oldDelegate.progress != progress ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.tickColor != tickColor;
  }
}
