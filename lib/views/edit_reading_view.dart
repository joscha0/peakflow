import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:peakflow/db/prefs.dart';
import 'package:peakflow/l10n/l10n.dart';
import 'package:peakflow/models/day_entry_model.dart';
import 'package:peakflow/models/reading_model.dart';
import 'package:peakflow/providers/day_entries_provider.dart';
import 'package:peakflow/views/day_view.dart';
import 'package:peakflow/widgets/peak_flow_value_selector.dart';

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
  int colorReferenceMaxValue = 850;
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
                    context.l10n.timeLabel,
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
    final l10n = context.l10n;
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final dateText = DateFormat(
      "dd.MM.yyyy",
      localeName,
    ).format(widget.dayEntry.date);
    final effectiveColorReferenceMaxValue = ref
        .watch(colorReferenceMaxValueProvider)
        .maybeWhen(
          data: (value) => value,
          orElse: () => colorReferenceMaxValue,
        );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.editReadingTitle), centerTitle: true),
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
                l10n.editReadingIntro(dateText),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionLabel(
                context,
                l10n.whenTitle,
                l10n.editReadingWhenDescription(dateText),
              ),
              _buildTimeButton(context),
              _buildSectionDivider(context),
              _buildSectionLabel(
                context,
                l10n.peakFlowValueTitle,
                l10n.editReadingValueDescription,
              ),
              const SizedBox(height: 8),
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
                  l10n.maximumReading(effectiveColorReferenceMaxValue),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
                  ),
                ),
              ),
              _buildSectionDivider(context),
              _buildSectionLabel(
                context,
                l10n.notesTitle,
                l10n.readingNotesDescription,
              ),
              TextFormField(
                controller: noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: l10n.readingNotesLabel,
                  hintText: l10n.readingNotesHint,
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
          await ref.read(entryListProvider.notifier).loadEntries();
          ref.invalidate(colorReferenceMaxValueProvider);
          if (!context.mounted) {
            return;
          }
          Navigator.pop(context);
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation1, animation2) =>
                  DayView(dayEntry: newEntry),
              transitionDuration: const Duration(seconds: 0),
            ),
          );
        },
        label: Text(l10n.saveUpper),
        icon: const Icon(Icons.save),
      ),
    );
  }
}
