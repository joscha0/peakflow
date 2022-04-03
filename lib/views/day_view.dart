import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:peakflow/providers/day_entries_provider.dart';
import 'package:peakflow/db/prefs.dart';
import 'package:peakflow/global/helper.dart';
import 'package:peakflow/models/day_entry_model.dart';
import 'package:peakflow/models/reading_model.dart';
import 'package:peakflow/views/add_view.dart';
import 'package:peakflow/views/edit_day_view.dart';
import 'package:peakflow/views/edit_reading_view.dart';

class DayView extends StatefulHookConsumerWidget {
  const DayView({Key? key, required this.dayEntry, required this.bestValue})
      : super(key: key);

  final DayEntry dayEntry;
  final int bestValue;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _DayViewState();
}

class _DayViewState extends ConsumerState<DayView> {
  List<String> symptoms = [];

  @override
  void initState() {
    for (String symptom in widget.dayEntry.checkboxValues.keys) {
      if (widget.dayEntry.checkboxValues[symptom] ?? false) {
        symptoms.add(symptom);
      }
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat("dd.MM.yyyy").format(widget.dayEntry.date)),
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
                await deleteDay(widget.dayEntry.date);
                ref.read(entryListProvider.notifier).getEntries();
                Navigator.of(context).pop();
              } else if (value == "edit") {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => EditDayView(dayEntry: widget.dayEntry)));
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(children: [
            if (widget.dayEntry.note != "") ...[
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
                              fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        Text(widget.dayEntry.note),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 8,
              ),
            ],
            if (symptoms.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: const [
                    Text(
                      "Symptoms",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: 8,
                children: [
                  for (String symptom in symptoms) ...[
                    Chip(
                      label: Text(symptom),
                      backgroundColor: Colors.blueAccent.shade700,
                    ),
                  ],
                ],
              ),
              const SizedBox(
                height: 8,
              ),
            ],
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: const [
                  Text(
                    "Readings",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
            ),
            for (Reading reading in widget.dayEntry.readings) ...[
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
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Icon(
                                  reading.time.hour < 12
                                      ? Icons.light_mode
                                      : Icons.nights_stay,
                                  color:
                                      getColor(reading.value, widget.bestValue),
                                ),
                                Text(
                                  reading.value.toString(),
                                  style: TextStyle(
                                    fontSize: 24,
                                    color: getColor(
                                        reading.value, widget.bestValue),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Flexible(
                            child: Column(
                              children: [
                                Text(reading.time.format(context)),
                              ],
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
                                            Icon(choice == "edit"
                                                ? Icons.edit
                                                : Icons.delete),
                                          ],
                                        ),
                                      ),
                                    )
                                    .toList();
                              },
                              onSelected: (value) async {
                                if (value == "delete") {
                                  await deleteReading(
                                      widget.dayEntry.date,
                                      widget.dayEntry.readings
                                          .indexOf(reading));
                                  widget.dayEntry.readings.remove(reading);
                                  ref
                                      .read(entryListProvider.notifier)
                                      .getEntries();
                                  setState(() {});
                                } else if (value == "edit") {
                                  Navigator.of(context).push(MaterialPageRoute(
                                      builder: (_) => EditReadingView(
                                          reading: reading,
                                          readingIndex: widget.dayEntry.readings
                                              .indexOf(reading),
                                          dayEntry: widget.dayEntry)));
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
              )
            ]
          ]),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => AddView(
                    date: widget.dayEntry.date,
                  )));
        },
        label: const Text("Add reading"),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
