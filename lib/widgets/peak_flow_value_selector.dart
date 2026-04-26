import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PeakFlowValueSelector extends StatefulWidget {
  const PeakFlowValueSelector({
    super.key,
    required this.value,
    required this.maxVolume,
    required this.onChanged,
    this.referenceMaxVolume,
    this.onDraggingChanged,
    this.valueAboveMeter = false,
  });

  final double value;
  final int maxVolume;
  final int? referenceMaxVolume;
  final ValueChanged<double> onChanged;
  final ValueChanged<bool>? onDraggingChanged;
  final bool valueAboveMeter;

  @override
  State<PeakFlowValueSelector> createState() => _PeakFlowValueSelectorState();
}

class _PeakFlowValueSelectorState extends State<PeakFlowValueSelector> {
  final valueController = TextEditingController();
  bool isDragging = false;
  late double _currentValue;

  int get _effectiveReferenceMaxVolume {
    final reference = widget.referenceMaxVolume ?? widget.maxVolume;
    return reference.clamp(1, widget.maxVolume);
  }

  @override
  void initState() {
    super.initState();
    _currentValue = _clampValue(widget.value);
    _syncValueText(_currentValue.round());
  }

  @override
  void didUpdateWidget(covariant PeakFlowValueSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!isDragging &&
        (oldWidget.value.round() != widget.value.round() ||
            oldWidget.maxVolume != widget.maxVolume)) {
      _currentValue = _clampValue(widget.value);
      _syncValueText(_currentValue.round());
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

  double _clampValue(double value) {
    return value.clamp(0, widget.maxVolume.toDouble()).toDouble();
  }

  double _normalizeValue(double value) {
    final snappedValue = (_clampValue(value) / 10).round() * 10;
    return _clampValue(snappedValue.toDouble());
  }

  void _setCurrentValue(double value) {
    if (_currentValue == value) {
      return;
    }

    setState(() {
      _currentValue = value;
    });
  }

  void _updateValue(double value, {bool notifyParent = true}) {
    final normalizedValue = _normalizeValue(value);
    _setCurrentValue(normalizedValue);
    _syncValueText(normalizedValue.round());

    if (notifyParent) {
      widget.onChanged(normalizedValue);
    }
  }

  void _commitValue() {
    widget.onChanged(_currentValue);
  }

  bool _isPositionOnSelectorLine(Offset localPosition, Size size) {
    final geometry = _PeakFlowMeterGeometry.fromSize(size);
    return geometry.interactionRect.contains(localPosition);
  }

  void _updateValueFromPosition(Offset localPosition, Size size) {
    final geometry = _PeakFlowMeterGeometry.fromSize(size);
    final clampedDx = localPosition.dx.clamp(
      geometry.trackRect.left,
      geometry.trackRect.right,
    );
    final progress =
        (clampedDx - geometry.trackRect.left) / geometry.trackRect.width;
    _updateValue(progress * widget.maxVolume, notifyParent: false);
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
    _setCurrentValue(clampedValue.toDouble());
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
    final progress = widget.maxVolume == 0
        ? 0.0
        : (_currentValue / widget.maxVolume).clamp(0.0, 1.0);
    final referenceMaxVolume = _effectiveReferenceMaxVolume;

    return LayoutBuilder(
      builder: (context, constraints) {
        final meterWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : 440.0;
        final meterHeight = meterWidth * 0.35;
        final meterSize = Size(meterWidth, meterHeight);

        final meter = _buildMeter(
          context,
          meterWidth,
          meterHeight,
          meterSize,
          referenceMaxVolume,
          progress,
        );
        final valueInput = _buildValueInput(context);

        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.valueAboveMeter) ...[
                valueInput,
                const SizedBox(height: 8),
                meter,
              ] else ...[
                meter,
                valueInput,
              ],
              const SizedBox(height: 6),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ZoneChip(label: '<50%', color: const Color(0xFFC62828)),
                  _ZoneChip(label: '50-79%', color: const Color(0xFFF9A825)),
                  _ZoneChip(label: '80-100%', color: const Color(0xFF2E7D32)),
                ],
              ),
              const SizedBox(height: 6),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMeter(
    BuildContext context,
    double meterWidth,
    double meterHeight,
    Size meterSize,
    int referenceMaxVolume,
    double progress,
  ) {
    final theme = Theme.of(context);

    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (event) {
        if (!_isPositionOnSelectorLine(event.localPosition, meterSize)) {
          return;
        }

        _setDragging(true);
        _updateValueFromPosition(event.localPosition, meterSize);
      },
      onPointerMove: (event) {
        if (!isDragging) {
          return;
        }

        _updateValueFromPosition(event.localPosition, meterSize);
      },
      onPointerUp: (_) {
        _commitValue();
        _setDragging(false);
      },
      onPointerCancel: (_) {
        _commitValue();
        _setDragging(false);
      },
      child: SizedBox(
        width: meterWidth,
        height: meterHeight,
        child: CustomPaint(
          size: meterSize,
          painter: _PeakFlowMeterPainter(
            maxVolume: widget.maxVolume,
            referenceMaxVolume: referenceMaxVolume,
            progress: progress,
            activeColor: theme.colorScheme.primary,
            shellColor: theme.colorScheme.onSurface.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.14 : 0.1,
            ),
            faceColor: theme.colorScheme.onSurface.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.09 : 0.06,
            ),
            meterMarkColor: theme.colorScheme.primary.withValues(alpha: 0.36),
            textColor: theme.colorScheme.onSurface.withValues(alpha: 0.62),
            channelColor: theme.dividerColor.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }

  Widget _buildValueInput(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 170,
          child: TextFormField(
            controller: valueController,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
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
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

class _ZoneChip extends StatelessWidget {
  const _ZoneChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PeakFlowMeterGeometry {
  const _PeakFlowMeterGeometry({
    required this.bodyRect,
    required this.faceRect,
    required this.mouthpieceRect,
    required this.trackRect,
    required this.selectorY,
    required this.interactionRect,
    required this.zoneRect,
    required this.scaleTopY,
    required this.scaleBottomY,
    required this.labelY,
  });

  final Rect bodyRect;
  final RRect faceRect;
  final RRect mouthpieceRect;
  final Rect trackRect;
  final double selectorY;
  final Rect interactionRect;
  final Rect zoneRect;
  final double scaleTopY;
  final double scaleBottomY;
  final double labelY;

  static _PeakFlowMeterGeometry fromSize(Size size) {
    final outerPadding = size.width * 0.025;
    final bodyHeight = size.height * 0.66;
    final bodyTop = size.height * 0.04;
    final mouthpieceWidth = bodyHeight * 0.24;
    final bodyLeft = outerPadding + (mouthpieceWidth * 0.55);
    final bodyWidth = size.width - bodyLeft - outerPadding;
    final bodyRect = Rect.fromLTWH(bodyLeft, bodyTop, bodyWidth, bodyHeight);

    final faceInsetX = bodyWidth * 0.052;
    final faceInsetTop = bodyHeight * 0.16;
    final faceInsetBottom = bodyHeight * 0.16;
    final faceRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        bodyRect.left + faceInsetX,
        bodyRect.top + faceInsetTop,
        bodyWidth - (faceInsetX * 2),
        bodyHeight - faceInsetTop - faceInsetBottom,
      ),
      Radius.circular(bodyHeight * 0.18),
    );

    final mouthpieceRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(bodyRect.left - bodyHeight * 0.11, bodyRect.center.dy),
        width: mouthpieceWidth,
        height: bodyHeight * 0.22,
      ),
      Radius.circular(bodyHeight * 0.07),
    );

    final selectorY = faceRect.top + (faceRect.height * 0.48);
    final trackRect = Rect.fromLTWH(
      faceRect.left + (faceRect.width * 0.05),
      selectorY - (faceRect.height * 0.105),
      faceRect.width * 0.9,
      faceRect.height * 0.21,
    );

    final interactionRect = Rect.fromLTWH(
      trackRect.left - 14,
      trackRect.top - bodyHeight * 0.4,
      trackRect.width + 28,
      trackRect.height + bodyHeight * 0.8,
    );

    final zoneRect = Rect.fromLTWH(
      trackRect.left,
      trackRect.top - faceRect.height * 0.23,
      trackRect.width,
      faceRect.height * 0.15,
    );

    final scaleTopY = trackRect.bottom + faceRect.height * 0.08;
    final scaleBottomY = trackRect.bottom + faceRect.height * 0.24;
    final labelY = scaleBottomY + faceRect.height * 0.22;

    return _PeakFlowMeterGeometry(
      bodyRect: bodyRect,
      faceRect: faceRect,
      mouthpieceRect: mouthpieceRect,
      trackRect: trackRect,
      selectorY: selectorY,
      interactionRect: interactionRect,
      zoneRect: zoneRect,
      scaleTopY: scaleTopY,
      scaleBottomY: scaleBottomY,
      labelY: labelY,
    );
  }
}

class _PeakFlowMeterPainter extends CustomPainter {
  const _PeakFlowMeterPainter({
    required this.maxVolume,
    required this.referenceMaxVolume,
    required this.progress,
    required this.activeColor,
    required this.shellColor,
    required this.faceColor,
    required this.meterMarkColor,
    required this.textColor,
    required this.channelColor,
  });

  final int maxVolume;
  final int referenceMaxVolume;
  final double progress;
  final Color activeColor;
  final Color shellColor;
  final Color faceColor;
  final Color meterMarkColor;
  final Color textColor;
  final Color channelColor;

  @override
  void paint(Canvas canvas, Size size) {
    final geometry = _PeakFlowMeterGeometry.fromSize(size);
    final knobX = _positionForValue(progress * maxVolume, geometry);
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    final shellPaint = Paint()..color = shellColor;
    final facePaint = Paint()..color = faceColor;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        geometry.bodyRect.shift(const Offset(0, 5)),
        const Radius.circular(24),
      ),
      shadowPaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(geometry.bodyRect, const Radius.circular(24)),
      shellPaint,
    );
    canvas.drawRRect(geometry.mouthpieceRect, Paint()..color = shellColor);
    canvas.drawRRect(geometry.faceRect, facePaint);

    _paintZones(canvas, geometry);
    _paintTrack(canvas, geometry, knobX);
    _paintScale(canvas, geometry);
  }

  void _paintZones(Canvas canvas, _PeakFlowMeterGeometry geometry) {
    final redRight = _positionForValue(referenceMaxVolume * 0.5, geometry);
    final orangeRight = _positionForValue(referenceMaxVolume * 0.8, geometry);

    final redRect = Rect.fromLTRB(
      geometry.zoneRect.left,
      geometry.zoneRect.top,
      redRight,
      geometry.zoneRect.bottom,
    );
    final orangeRect = Rect.fromLTRB(
      redRight + 4,
      geometry.zoneRect.top,
      orangeRight,
      geometry.zoneRect.bottom,
    );
    final greenRect = Rect.fromLTRB(
      orangeRight + 4,
      geometry.zoneRect.top,
      geometry.zoneRect.right,
      geometry.zoneRect.bottom,
    );

    if (redRect.width > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(redRect, const Radius.circular(8)),
        Paint()..color = const Color(0xFFC62828).withValues(alpha: 0.35),
      );
    }
    if (orangeRect.width > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(orangeRect, const Radius.circular(8)),
        Paint()..color = const Color(0xFFEF6C00).withValues(alpha: 0.35),
      );
    }
    if (greenRect.width > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(greenRect, const Radius.circular(8)),
        Paint()..color = const Color(0xFF2E7D32).withValues(alpha: 0.35),
      );
    }
  }

  void _paintTrack(
    Canvas canvas,
    _PeakFlowMeterGeometry geometry,
    double knobX,
  ) {
    final channelRRect = RRect.fromRectAndRadius(
      geometry.trackRect,
      Radius.circular(geometry.trackRect.height),
    );
    final selectorGlowRect = Rect.fromCenter(
      center: geometry.trackRect.center,
      width: geometry.trackRect.width + 20,
      height: geometry.trackRect.height * 4.6,
    );

    canvas.drawRRect(channelRRect, Paint()..color = channelColor);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(
          geometry.trackRect.left,
          geometry.trackRect.top,
          knobX,
          geometry.trackRect.bottom,
        ),
        Radius.circular(geometry.trackRect.height),
      ),
      Paint()..color = activeColor.withValues(alpha: 0.14),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        selectorGlowRect,
        Radius.circular(selectorGlowRect.height),
      ),
      Paint()..color = activeColor.withValues(alpha: 0.08),
    );

    canvas.drawLine(
      Offset(knobX, geometry.trackRect.top - 22),
      Offset(knobX, geometry.trackRect.bottom + 22),
      Paint()
        ..color = activeColor
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );

    final handleRect = Rect.fromCenter(
      center: Offset(knobX, geometry.selectorY),
      width: geometry.trackRect.height * 1.55,
      height: geometry.trackRect.height * 4.3,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        handleRect,
        Radius.circular(handleRect.height / 2),
      ),
      Paint()..color = activeColor,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        handleRect.deflate(handleRect.height * 0.22),
        Radius.circular(handleRect.height / 2),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.86),
    );
  }

  void _paintScale(Canvas canvas, _PeakFlowMeterGeometry geometry) {
    final tickPaint = Paint()
      ..color = meterMarkColor
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final labelStyle = TextStyle(
      color: textColor,
      fontSize: 10,
      fontWeight: FontWeight.w600,
    );
    final labelStep = _labelStep(maxVolume);

    for (var value = 0; value <= maxVolume; value += 10) {
      final x = _positionForValue(value.toDouble(), geometry);
      final isMajorTick = value % labelStep == 0;
      final startY = geometry.scaleTopY;
      final endY = isMajorTick ? geometry.scaleBottomY : geometry.scaleTopY + 8;

      canvas.drawLine(Offset(x, startY), Offset(x, endY), tickPaint);

      if (isMajorTick && value > 0) {
        final textPainter = TextPainter(
          text: TextSpan(text: value.toString(), style: labelStyle),
          textDirection: TextDirection.ltr,
        )..layout();

        canvas.save();
        canvas.translate(x, geometry.labelY);
        canvas.rotate(math.pi / 2);
        textPainter.paint(
          canvas,
          Offset(-textPainter.width / 2, -textPainter.height / 2),
        );
        canvas.restore();
      }
    }
  }

  int _labelStep(int maxVolume) {
    if (maxVolume <= 400) {
      return 50;
    }
    if (maxVolume <= 650) {
      return 75;
    }
    return 100;
  }

  double _positionForValue(double value, _PeakFlowMeterGeometry geometry) {
    final normalized = (value.clamp(0, maxVolume.toDouble())) / maxVolume;
    return geometry.trackRect.left + (geometry.trackRect.width * normalized);
  }

  @override
  bool shouldRepaint(covariant _PeakFlowMeterPainter oldDelegate) {
    return oldDelegate.maxVolume != maxVolume ||
        oldDelegate.referenceMaxVolume != referenceMaxVolume ||
        oldDelegate.progress != progress ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.shellColor != shellColor ||
        oldDelegate.faceColor != faceColor ||
        oldDelegate.meterMarkColor != meterMarkColor ||
        oldDelegate.textColor != textColor ||
        oldDelegate.channelColor != channelColor;
  }
}
