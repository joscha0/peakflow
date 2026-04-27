import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:peakflow/db/prefs.dart';
import 'package:peakflow/global/consts.dart';
import 'package:peakflow/providers/day_entries_provider.dart';
import 'package:peakflow/widgets/peak_flow_value_selector.dart';

Future<void> showAddReadingDrawer(BuildContext context, {DateTime? date}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => AddView(date: date),
  );
}

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
  bool showAdvanced = false;
  double sliderValue = 0;
  int maxVolume = 850;
  int colorReferenceMaxValue = 850;
  final noteController = TextEditingController();
  final noteDayController = TextEditingController();

  Map<String, bool> checkboxValues = Map<String, bool>.from(
    defaultCheckboxValues,
  );

  void pickDate(BuildContext context) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final firstDate = DateTime(2000, 1, 1);
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
    final entry = await getDayEntry(date);
    if (!mounted) {
      return;
    }
    if (entry != null) {
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
    final values = await Future.wait<int>([
      getDeviceMaxValue(),
      getColorReferenceMaxValue(),
    ]);
    if (!mounted) {
      return;
    }
    setState(() {
      maxVolume = values[0];
      colorReferenceMaxValue = values[1];
      sliderValue = sliderValue.clamp(0, maxVolume.toDouble());
    });
  }

  @override
  void dispose() {
    noteController.dispose();
    noteDayController.dispose();
    super.dispose();
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

  Widget _buildAdvancedToggle(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = showAdvanced
        ? theme.colorScheme.primary.withValues(alpha: 0.08)
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.42);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          setState(() {
            showAdvanced = !showAdvanced;
          });
        },
        child: Ink(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.tune_rounded,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Advanced',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Add date, notes, and symptoms for this day.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.68,
                          ),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedRotation(
                  turns: showAdvanced ? 0.5 : 0,
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                    size: 30,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveReading() async {
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
    await ref.read(entryListProvider.notifier).loadEntries();
    ref.invalidate(colorReferenceMaxValueProvider);
    if (!mounted) {
      return;
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomSafeArea = MediaQuery.viewPaddingOf(context).bottom;
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final maxSheetHeight = MediaQuery.sizeOf(context).height * 0.92;
    final effectiveColorReferenceMaxValue = ref
        .watch(colorReferenceMaxValueProvider)
        .maybeWhen(
          data: (value) => value,
          orElse: () => colorReferenceMaxValue,
        );

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: maxSheetHeight),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 5,
                      decoration: BoxDecoration(
                        color: theme.dividerColor.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Add Reading',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Flexible(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  physics: isDraggingSelector
                      ? const NeverScrollableScrollPhysics()
                      : const ClampingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Drag the center line to set the reading or tap the number to type it.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.72,
                          ),
                          height: 1.35,
                        ),
                      ),
                      PeakFlowValueSelector(
                        value: sliderValue,
                        maxVolume: maxVolume,
                        referenceMaxVolume: effectiveColorReferenceMaxValue,
                        valueAboveMeter: true,
                        onChanged: (value) {
                          setState(() {
                            sliderValue = value;
                          });
                        },
                        onDraggingChanged: (isDragging) {
                          setState(() {
                            isDraggingSelector = isDragging;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          'Maximum reading: $effectiveColorReferenceMaxValue L/min',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.68,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      _buildAdvancedToggle(context),
                      AnimatedCrossFade(
                        firstChild: const SizedBox(width: double.infinity),
                        secondChild: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionDivider(context),
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
                                      value: DateFormat(
                                        "dd.MM.yyyy",
                                      ).format(date),
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
                                    selectedColor: theme.colorScheme.primary
                                        .withValues(alpha: 0.16),
                                    side: BorderSide(
                                      color: (checkboxValues[checkBox] ?? false)
                                          ? theme.colorScheme.primary
                                          : theme.dividerColor.withValues(
                                              alpha: 0.85,
                                            ),
                                    ),
                                    labelStyle: theme.textTheme.bodyMedium
                                        ?.copyWith(
                                          color:
                                              (checkboxValues[checkBox] ??
                                                  false)
                                              ? theme.colorScheme.primary
                                              : null,
                                          fontWeight:
                                              (checkboxValues[checkBox] ??
                                                  false)
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
                                hintText:
                                    "Weather, medication, exercise, triggers...",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                            ),
                          ],
                        ),
                        crossFadeState: showAdvanced
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 180),
                        sizeCurve: Curves.easeOut,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomSafeArea),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _saveReading,
                    icon: const Icon(Icons.save),
                    label: const Text('Save'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
