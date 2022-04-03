import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:peakflow/db/prefs.dart';
import 'package:peakflow/global/consts.dart';
import 'package:peakflow/models/day_entry_model.dart';
import 'package:peakflow/providers/day_entries_provider.dart';
import 'package:peakflow/views/day_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditDayView extends StatefulHookConsumerWidget {
  final DayEntry dayEntry;

  const EditDayView({Key? key, required this.dayEntry}) : super(key: key);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _EditDayViewState();
}

class _EditDayViewState extends ConsumerState<EditDayView> {
  final noteDayController = TextEditingController();
  Map<String, bool> checkboxValues =
      Map<String, bool>.from(defaultCheckboxValues);

  @override
  void initState() {
    getDay();
    super.initState();
  }

  void getDay() async {
    final prefs = await SharedPreferences.getInstance();
    String key = DateFormat("yyyyMMdd").format(widget.dayEntry.date);
    String? jsonData = prefs.getString(key);
    if (jsonData != null) {
      DayEntry entry = DayEntry.fromJson(json.decode(jsonData));
      setState(() {
        noteDayController.text = entry.note;
        checkboxValues = entry.checkboxValues;
      });
    } else {
      noteDayController.text = "";
      checkboxValues = Map<String, bool>.from(defaultCheckboxValues);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            "Edit day [${DateFormat("dd.MM.yyyy").format(widget.dayEntry.date)}]"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              TextFormField(
                controller: noteDayController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Notes day",
                  hintText: "...",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(
                height: 24,
              ),
              const Text(
                "Symptoms of the day",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(
                height: 8,
              ),
              for (String checkBox in checkboxValues.keys) ...[
                CheckboxListTile(
                    value: checkboxValues[checkBox],
                    title: Text(checkBox),
                    onChanged: (value) {
                      setState(() {
                        checkboxValues[checkBox] = value ?? false;
                      });
                    }),
              ],
              const SizedBox(
                height: 32,
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          DayEntry newEntry = await updateDay(
              widget.dayEntry, noteDayController.text, checkboxValues);
          int bestValue = await getBestValue();
          ref.read(entryListProvider.notifier).getEntries();
          Navigator.pop(context);
          Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation1, animation2) =>
                    DayView(dayEntry: newEntry, bestValue: bestValue),
                transitionDuration: const Duration(seconds: 0),
              ));
        },
        label: const Text("SAVE"),
        icon: const Icon(Icons.save),
      ),
    );
  }
}
