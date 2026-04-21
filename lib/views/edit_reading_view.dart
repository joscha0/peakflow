import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:peakflow/db/prefs.dart';
import 'package:peakflow/models/day_entry_model.dart';
import 'package:peakflow/models/reading_model.dart';
import 'package:peakflow/providers/day_entries_provider.dart';
import 'package:peakflow/views/day_view.dart';
import 'package:peakflow/widgets/peak_flow_value_selector.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditReadingView extends ConsumerStatefulWidget {
  final Reading reading;
  final DayEntry dayEntry;
  final int readingIndex;

  const EditReadingView({
    super.key,
    required this.reading,
    required this.readingIndex,
    required this.dayEntry,
  });

  @override
  ConsumerState<EditReadingView> createState() => _EditReadingViewState();
}

class _EditReadingViewState extends ConsumerState<EditReadingView> {
  bool isDraggingSelector = false;
  late TimeOfDay time;
  double sliderValue = 0;
  int maxVolume = 850;
  final noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    time = widget.reading.time;
    sliderValue = widget.reading.value.toDouble();
    noteController.text = widget.reading.note;
    loadMax();
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
  }

  void pickTime(BuildContext context) async {
    time = await showTimePicker(context: context, initialTime: time) ?? time;
    setState(() {});
  }

  @override
  void dispose() {
    noteController.dispose();
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

  Widget _buildTimeButton(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () {
          pickTime(context);
        },
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
            Icon(Icons.access_time_outlined, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Time',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    time.format(context),
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
    final dateText = DateFormat("dd.MM.yyyy").format(widget.dayEntry.date);

    return Scaffold(
      appBar: AppBar(title: const Text("Edit reading"), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: isDraggingSelector
              ? const NeverScrollableScrollPhysics()
              : null,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Update the reading details for $dateText.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionLabel(
                context,
                'When',
                'This reading belongs to $dateText. You can adjust the time here.',
              ),
              _buildTimeButton(context),
              _buildSectionDivider(context),
              _buildSectionLabel(
                context,
                'Peak Flow Value',
                'Drag the half-circle to update the reading or type the value directly.',
              ),
              const SizedBox(height: 8),
              PeakFlowValueSelector(
                value: sliderValue,
                maxVolume: maxVolume,
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
                  'Maximum range: $maxVolume L/min',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
                  ),
                ),
              ),
              _buildSectionDivider(context),
              _buildSectionLabel(
                context,
                'Notes',
                'Adjust the note for this individual reading.',
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
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          DayEntry newEntry = await updateReading(
            widget.dayEntry,
            Reading(
              time: time,
              value: sliderValue.round(),
              note: noteController.text,
            ),
            widget.readingIndex,
          );
          int bestValue = await getBestValue();
          ref.read(entryListProvider.notifier).loadEntries();
          if (!context.mounted) {
            return;
          }
          Navigator.pop(context);
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation1, animation2) =>
                  DayView(dayEntry: newEntry, bestValue: bestValue),
              transitionDuration: const Duration(seconds: 0),
            ),
          );
        },
        label: const Text("SAVE"),
        icon: const Icon(Icons.save),
      ),
    );
  }
}
