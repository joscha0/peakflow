import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:peakflow/db/prefs.dart';
import 'package:peakflow/global/helper.dart';
import 'package:peakflow/l10n/l10n.dart';
import 'package:peakflow/models/day_entry_model.dart';
import 'package:peakflow/providers/day_entries_provider.dart';
import 'package:peakflow/providers/day_entries_state.dart';
import 'package:peakflow/views/add_view.dart';
import 'package:peakflow/views/edit_day_view.dart';
import 'package:peakflow/views/edit_reading_view.dart';

Future<bool> showDeletionConfirmationDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmLabel,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );

  return confirmed ?? false;
}

class DayView extends ConsumerStatefulWidget {
  const DayView({super.key, required this.dayEntry});

  final DayEntry dayEntry;

  @override
  ConsumerState<DayView> createState() => _DayViewState();
}

class _DayViewState extends ConsumerState<DayView> {
  bool _isDeletingDay = false;

  DayEntry _currentDayEntry(List<DayEntry> entries) {
    for (final entry in entries) {
      if (_isSameDate(entry.date, widget.dayEntry.date)) {
        return entry;
      }
    }
    return widget.dayEntry;
  }

  bool _isSameDate(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  Future<void> _handleDaySelection(String value, DayEntry dayEntry) async {
    await Future<void>.delayed(Duration.zero);
    if (!mounted) {
      return;
    }

    if (value == "delete") {
      final confirmed = await showDeletionConfirmationDialog(
        context: context,
        title: context.l10n.deleteDayTitle,
        message: context.l10n.deleteDayMessage,
        confirmLabel: context.l10n.deleteDayConfirm,
      );
      if (!confirmed || !mounted) {
        return;
      }
      final entriesNotifier = ref.read(entryListProvider.notifier);
      setState(() {
        _isDeletingDay = true;
      });
      entriesNotifier.removeDay(dayEntry.date);
      Navigator.of(context).pop();
      unawaited(_deleteDayAndRefresh(entriesNotifier, dayEntry.date));
    } else if (value == "edit") {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => EditDayView(dayEntry: dayEntry)),
      );
    }
  }

  Future<void> _handleReadingSelection(
    String value,
    DayEntry dayEntry,
    int readingIndex,
  ) async {
    await Future<void>.delayed(Duration.zero);
    if (!mounted) {
      return;
    }

    if (value == "delete") {
      final confirmed = await showDeletionConfirmationDialog(
        context: context,
        title: context.l10n.deleteReadingTitle,
        message: context.l10n.deleteReadingMessage,
        confirmLabel: context.l10n.deleteReadingConfirm,
      );
      if (!confirmed || !mounted) {
        return;
      }
      await deleteReading(dayEntry.date, readingIndex);
      ref.invalidate(colorReferenceMaxValueProvider);
      await ref.read(entryListProvider.notifier).loadEntries();
      if (!mounted) {
        return;
      }
      setState(() {});
    } else if (value == "edit") {
      final reading = dayEntry.readings[readingIndex];
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EditReadingView(
            reading: reading,
            readingIndex: readingIndex,
            dayEntry: dayEntry,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isDeletingDay) {
      return const Scaffold(body: SizedBox.shrink());
    }

    final dayEntry = _currentDayEntry(ref.watch(entryListProvider));
    final l10n = context.l10n;
    final referenceMaxValue = ref
        .watch(colorReferenceMaxValueProvider)
        .maybeWhen(data: (value) => value, orElse: () => defaultMaxVolume);
    final symptoms = dayEntry.checkboxValues.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat("dd.MM.yyyy").format(dayEntry.date)),
        actions: [
          PopupMenuButton<void>(
            itemBuilder: (_) {
              return [
                PopupMenuItem<void>(
                  onTap: () => unawaited(_handleDaySelection("edit", dayEntry)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [Text(l10n.edit), const Icon(Icons.edit)],
                  ),
                ),
                PopupMenuItem<void>(
                  onTap: () =>
                      unawaited(_handleDaySelection("delete", dayEntry)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [Text(l10n.delete), const Icon(Icons.delete)],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              if (dayEntry.note != "") ...[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.notesTitle,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            Text(dayEntry.note),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (symptoms.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Text(
                        l10n.symptomsTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    for (String symptom in symptoms) ...[
                      Chip(
                        label: Text(
                          l10n.symptomLabel(symptom),
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: Colors.blueAccent.shade700,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
              ],
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Text(
                      l10n.readingsTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
              for (final reading in dayEntry.readings) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Icon(
                                    reading.time.hour < 12
                                        ? Icons.light_mode
                                        : Icons.nights_stay,
                                    color: getColor(
                                      reading.value,
                                      referenceMaxValue,
                                    ),
                                  ),
                                  Text(
                                    reading.value.toString(),
                                    style: TextStyle(
                                      fontSize: 24,
                                      color: getColor(
                                        reading.value,
                                        referenceMaxValue,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Flexible(
                              child: Column(
                                children: [Text(reading.time.format(context))],
                              ),
                            ),
                            Flexible(
                              child: PopupMenuButton<void>(
                                itemBuilder: (_) {
                                  final readingIndex = dayEntry.readings
                                      .indexOf(reading);
                                  return [
                                    PopupMenuItem<void>(
                                      onTap: readingIndex < 0
                                          ? null
                                          : () => unawaited(
                                              _handleReadingSelection(
                                                "edit",
                                                dayEntry,
                                                readingIndex,
                                              ),
                                            ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(l10n.edit),
                                          const Icon(Icons.edit),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem<void>(
                                      onTap: readingIndex < 0
                                          ? null
                                          : () => unawaited(
                                              _handleReadingSelection(
                                                "delete",
                                                dayEntry,
                                                readingIndex,
                                              ),
                                            ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(l10n.delete),
                                          const Icon(Icons.delete),
                                        ],
                                      ),
                                    ),
                                  ];
                                },
                              ),
                            ),
                          ],
                        ),
                        if (reading.note != "") ...[
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.notesPrefix,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Expanded(child: Text(reading.note)),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await showAddReadingDrawer(context, date: widget.dayEntry.date);
        },
        label: Text(l10n.addReadingButton),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _deleteDayAndRefresh(
    DayEntriesState entriesNotifier,
    DateTime date,
  ) async {
    try {
      await deleteDay(date);
    } finally {
      await entriesNotifier.loadEntries();
    }
  }
}
