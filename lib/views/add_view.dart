import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:peakflow/db/prefs.dart';
import 'package:peakflow/global/consts.dart';
import 'package:peakflow/models/day_entry_model.dart';
import 'package:peakflow/providers/day_entries_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddView extends ConsumerStatefulWidget {
  final DateTime? date;
  const AddView({super.key, this.date});

  @override
  ConsumerState<AddView> createState() => _AddViewState();
}

class _AddViewState extends ConsumerState<AddView> {
  final _formKey = GlobalKey<FormState>();

  late DateTime date;
  TimeOfDay time = TimeOfDay.now();
  bool isDraggingSelector = false;
  double sliderValue = 0;
  int maxVolume = 850;
  final valueController = TextEditingController(text: "0");
  final noteController = TextEditingController();
  final noteDayController = TextEditingController();

  Map<String, bool> checkboxValues = Map<String, bool>.from(
    defaultCheckboxValues,
  );

  void pickDate(BuildContext context) async {
    final today = DateTime.now();
    final firstDate = today.add(const Duration(days: -100));
    date =
        await showDatePicker(
          context: context,
          initialDate: date.isBefore(firstDate)
              ? firstDate
              : date.isAfter(today)
              ? today
              : date,
          firstDate: firstDate,
          lastDate: today,
        ) ??
        date;
    getDay();

    setState(() {});
  }

  void pickTime(BuildContext context) async {
    time =
        await showTimePicker(context: context, initialTime: TimeOfDay.now()) ??
        TimeOfDay.now();
    setState(() {});
  }

  @override
  void initState() {
    date = widget.date ?? DateTime.now();
    super.initState();
    getDay();
    loadMax();
  }

  Future<void> getDay() async {
    final prefs = await SharedPreferences.getInstance();
    String key = DateFormat("yyyyMMdd").format(date);
    String? jsonData = prefs.getString(key);
    if (!mounted) {
      return;
    }
    if (jsonData != null) {
      DayEntry entry = DayEntry.fromJson(json.decode(jsonData));
      setState(() {
        noteDayController.text = entry.note;
        checkboxValues = entry.checkboxValues;
      });
    } else {
      setState(() {
        noteDayController.text = "";
        checkboxValues = Map<String, bool>.from(defaultCheckboxValues);
      });
    }
  }

  Future<void> loadMax() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) {
      return;
    }
    setState(() {
      maxVolume = prefs.getInt("maxVolume") ?? 850;
      sliderValue = sliderValue.clamp(0, maxVolume.toDouble());
    });
    _syncValueText(sliderValue.round());
  }

  @override
  void dispose() {
    valueController.dispose();
    noteController.dispose();
    noteDayController.dispose();
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

  void _updateSliderValue(double value) {
    final snappedValue =
        ((value.clamp(0, maxVolume.toDouble())) / 10).round() * 10;
    final normalizedValue = snappedValue
        .toDouble()
        .clamp(0, maxVolume.toDouble())
        .toDouble();

    setState(() {
      sliderValue = normalizedValue;
    });
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
    _updateSliderValue(progress * maxVolume);
  }

  void _handleValueTextChanged(String value) {
    if (value.isEmpty) {
      return;
    }

    final parsedValue = int.tryParse(value);
    if (parsedValue == null) {
      return;
    }

    final clampedValue = parsedValue.clamp(0, maxVolume);
    if (sliderValue != clampedValue.toDouble()) {
      setState(() {
        sliderValue = clampedValue.toDouble();
      });
    }

    if (clampedValue != parsedValue) {
      _syncValueText(clampedValue);
    }
  }

  void _normalizeTypedValue() {
    final parsedValue = int.tryParse(valueController.text) ?? 0;
    _updateSliderValue(parsedValue.toDouble());
  }

  Widget _buildSectionLabel(
    BuildContext context,
    String title,
    String description,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionDivider(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Divider(
        height: 1,
        thickness: 1,
        color: Theme.of(context).dividerColor.withValues(alpha: 0.55),
      ),
    );
  }

  Widget _buildPickerButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onPressed,
    double? width,
  }) {
    final theme = Theme.of(context);

    return SizedBox(
      width: width,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.8)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadialSelector(BuildContext context) {
    final theme = Theme.of(context);
    final progress = maxVolume == 0 ? 0.0 : sliderValue / maxVolume;

    return LayoutBuilder(
      builder: (context, constraints) {
        final selectorSize = math.min(constraints.maxWidth, 320.0);
        final selectorHeight = selectorSize * 0.7;
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

                    setState(() {
                      isDraggingSelector = true;
                    });
                    _updateValueFromPosition(
                      event.localPosition,
                      selectorCanvasSize,
                    );
                  },
                  onPointerMove: (event) {
                    if (!isDraggingSelector) {
                      return;
                    }

                    _updateValueFromPosition(
                      event.localPosition,
                      selectorCanvasSize,
                    );
                  },
                  onPointerUp: (_) {
                    if (!isDraggingSelector) {
                      return;
                    }

                    setState(() {
                      isDraggingSelector = false;
                    });
                  },
                  onPointerCancel: (_) {
                    if (!isDraggingSelector) {
                      return;
                    }

                    setState(() {
                      isDraggingSelector = false;
                    });
                  },
                  child: SizedBox(
                    width: selectorSize,
                    height: selectorHeight,
                    child: CustomPaint(
                      size: selectorCanvasSize,
                      painter: _RadialValuePainter(
                        maxVolume: maxVolume,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Add reading"), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: isDraggingSelector
              ? const NeverScrollableScrollPhysics()
              : null,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Log a new measurement with quick context for the day.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionLabel(
                  context,
                  'When',
                  'Set the date and time for this reading first.',
                ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final stacked = constraints.maxWidth < 430;
                    final buttonWidth = stacked
                        ? double.infinity
                        : (constraints.maxWidth - 12) / 2;

                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _buildPickerButton(
                          context: context,
                          icon: Icons.calendar_today_outlined,
                          label: 'Date',
                          value: DateFormat("dd.MM.yyyy").format(date),
                          width: buttonWidth,
                          onPressed: () {
                            pickDate(context);
                          },
                        ),
                        _buildPickerButton(
                          context: context,
                          icon: Icons.access_time_outlined,
                          label: 'Time',
                          value: time.format(context),
                          width: buttonWidth,
                          onPressed: () {
                            pickTime(context);
                          },
                        ),
                      ],
                    );
                  },
                ),
                _buildSectionDivider(context),
                _buildSectionLabel(
                  context,
                  'Peak Flow Value',
                  'Drag the half-circle to set the reading or tap the number to type it.',
                ),
                _buildRadialSelector(context),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Maximum range: $maxVolume L/min',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.68,
                      ),
                    ),
                  ),
                ),
                _buildSectionDivider(context),
                _buildSectionLabel(
                  context,
                  'Notes',
                  'Add a note for this specific reading.',
                ),
                TextFormField(
                  controller: noteController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: "Reading notes",
                    hintText: "How did the measurement feel?",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
                _buildSectionDivider(context),
                _buildSectionLabel(
                  context,
                  'Symptoms of the Day',
                  'Tap every symptom that applies. These day symptoms and notes are shared across all readings for this date.',
                ),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final checkBox in checkboxValues.keys)
                      FilterChip(
                        label: Text(checkBox),
                        selected: checkboxValues[checkBox] ?? false,
                        showCheckmark: true,
                        checkmarkColor: theme.colorScheme.primary,
                        selectedColor: theme.colorScheme.primary.withValues(
                          alpha: 0.16,
                        ),
                        side: BorderSide(
                          color: (checkboxValues[checkBox] ?? false)
                              ? theme.colorScheme.primary
                              : theme.dividerColor.withValues(alpha: 0.85),
                        ),
                        labelStyle: theme.textTheme.bodyMedium?.copyWith(
                          color: (checkboxValues[checkBox] ?? false)
                              ? theme.colorScheme.primary
                              : null,
                          fontWeight: (checkboxValues[checkBox] ?? false)
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                        onSelected: (value) {
                          setState(() {
                            checkboxValues[checkBox] = value;
                          });
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: noteDayController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: "Day notes",
                    hintText: "Weather, medication, exercise, triggers...",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          if (!_formKey.currentState!.validate()) {
            return;
          }
          await addReading(
            date,
            time,
            sliderValue.round(),
            noteController.text,
            noteDayController.text,
            checkboxValues,
          );
          ref.read(entryListProvider.notifier).loadEntries();
          if (!context.mounted) {
            return;
          }
          Navigator.pop(context);
        },
        label: const Text("SAVE"),
        icon: const Icon(Icons.save),
      ),
    );
  }
}

class _RadialValuePainter extends CustomPainter {
  const _RadialValuePainter({
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
        final labelValue = ((((maxVolume / 12) * i) / 10).round() * 10);
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
  bool shouldRepaint(covariant _RadialValuePainter oldDelegate) {
    return oldDelegate.maxVolume != maxVolume ||
        oldDelegate.textColor != textColor ||
        oldDelegate.progress != progress ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.tickColor != tickColor;
  }
}
