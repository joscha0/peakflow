import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:peakflow/db/prefs.dart';
import 'package:peakflow/global/consts.dart';
import 'package:peakflow/providers/day_entries_provider.dart';
import 'package:peakflow/widgets/peak_flow_value_selector.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColorReferenceMaxValue = ref
        .watch(colorReferenceMaxValueProvider)
        .maybeWhen(
          data: (value) => value,
          orElse: () => colorReferenceMaxValue,
        );

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
                  'Drag the center line to set the reading or tap the number to type it.',
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
          await ref.read(entryListProvider.notifier).loadEntries();
          ref.invalidate(colorReferenceMaxValueProvider);
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
