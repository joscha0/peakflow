import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:peakflow/db/prefs.dart';
import 'package:peakflow/global/helper.dart';
import 'package:peakflow/models/day_entry_model.dart';
import 'package:peakflow/providers/day_entries_provider.dart';
import 'package:peakflow/providers/day_entries_state.dart';
import 'package:peakflow/views/add_view.dart';
import 'package:peakflow/views/edit_day_view.dart';
import 'package:peakflow/views/edit_reading_view.dart';

class DayView extends ConsumerStatefulWidget {
  const DayView({super.key, required this.dayEntry});

  final DayEntry dayEntry;

  @override
  ConsumerState<DayView> createState() => _DayViewState();
}

class _DayViewState extends ConsumerState<DayView> {
  int referenceMaxValue = defaultMaxVolume;
  bool _isDeletingDay = false;

  @override
  void initState() {
    super.initState();
    _loadReferenceMaxValue();
  }

  Future<void> _loadReferenceMaxValue() async {
    final loadedReferenceMaxValue = await getColorReferenceMaxValue();
    if (!mounted) {
      return;
    }
    setState(() {
      referenceMaxValue = loadedReferenceMaxValue;
    });
  }

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

  @override
  Widget build(BuildContext context) {
    if (_isDeletingDay) {
      return const Scaffold(body: SizedBox.shrink());
    }

    final dayEntry = _currentDayEntry(ref.watch(entryListProvider));
    final symptoms = dayEntry.checkboxValues.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat("dd.MM.yyyy").format(dayEntry.date)),
        actions: [
          PopupMenuButton(
            itemBuilder: (_) {
              return ["edit", "delete"]
                  .map(
                    (String choice) => PopupMenuItem(
                      value: choice,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(choice),
                          Icon(choice == "edit" ? Icons.edit : Icons.delete),
                        ],
                      ),
                    ),
                  )
                  .toList();
            },
            onSelected: (value) async {
              if (value == "delete") {
                final entriesNotifier = ref.read(entryListProvider.notifier);
                setState(() {
                  _isDeletingDay = true;
                });
                entriesNotifier.removeDay(dayEntry.date);
                if (!context.mounted) {
                  return;
                }
                Navigator.of(context).pop();
                unawaited(_deleteDayAndRefresh(entriesNotifier, dayEntry.date));
              } else if (value == "edit") {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => EditDayView(dayEntry: dayEntry),
                  ),
                );
              }
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Notes",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Text(dayEntry.note),
                        ],
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
                    children: const [
                      Text(
                        "Symptoms",
                        style: TextStyle(
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
                          symptom,
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
                  children: const [
                    Text(
                      "Readings",
                      style: TextStyle(
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
                              child: PopupMenuButton(
                                itemBuilder: (_) {
                                  return ["edit", "delete"]
                                      .map(
                                        (String choice) => PopupMenuItem(
                                          value: choice,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(choice),
                                              Icon(
                                                choice == "edit"
                                                    ? Icons.edit
                                                    : Icons.delete,
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                      .toList();
                                },
                                onSelected: (value) async {
                                  if (value == "delete") {
                                    final readingIndex = dayEntry.readings
                                        .indexOf(reading);
                                    if (readingIndex < 0) {
                                      return;
                                    }
                                    await deleteReading(
                                      dayEntry.date,
                                      readingIndex,
                                    );
                                    await _loadReferenceMaxValue();
                                    await ref
                                        .read(entryListProvider.notifier)
                                        .loadEntries();
                                    if (!context.mounted) {
                                      return;
                                    }
                                    setState(() {});
                                  } else if (value == "edit") {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => EditReadingView(
                                          reading: reading,
                                          readingIndex: dayEntry.readings
                                              .indexOf(reading),
                                          dayEntry: dayEntry,
                                        ),
                                      ),
                                    );
                                  }
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
                                const Text(
                                  "Notes: ",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(reading.note),
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
        onPressed: () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => AddView(date: widget.dayEntry.date),
            ),
          );
        },
        label: const Text("Add reading"),
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
