import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:peakflow/db/day_entries_provider.dart';
import 'package:peakflow/db/prefs.dart';
import 'package:peakflow/global/consts.dart';
import 'package:peakflow/models/day_entry_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddView extends StatefulHookConsumerWidget {
  const AddView({Key? key}) : super(key: key);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _AddViewState();
}

class _AddViewState extends ConsumerState<AddView> {
  final _formKey = GlobalKey<FormState>();

  DateTime date = DateTime.now();
  TimeOfDay time = TimeOfDay.now();
  double sliderValue = 0;
  final valueController = TextEditingController(text: "0");
  final noteController = TextEditingController();
  final noteDayController = TextEditingController();

  Map<String, bool> checkboxValues =
      Map<String, bool>.from(defaultCheckboxValues);

  void pickDate(BuildContext context) async {
    date = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime.now().add(const Duration(days: -100)),
            lastDate: DateTime.now()) ??
        DateTime.now();
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
    getDay();
    super.initState();
  }

  void getDay() async {
    final prefs = await SharedPreferences.getInstance();
    String key = DateFormat("yyyyMMdd").format(date);
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
        title: const Text("Add reading"),
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Row(
                      children: [
                        const Text("Date: "),
                        TextButton(
                            onPressed: () {
                              pickDate(context);
                            },
                            child: Text(DateFormat("dd.MM.yyyy").format(date))),
                      ],
                    ),
                    Row(
                      children: [
                        const Text("Time: "),
                        TextButton(
                            onPressed: () {
                              pickTime(context);
                            },
                            child: Text(time.format(context))),
                      ],
                    )
                  ],
                ),
                Row(
                  children: [
                    const Text("Value: "),
                    Flexible(
                      flex: 4,
                      child: Slider(
                        value: sliderValue,
                        max: 900,
                        divisions: 18,
                        label: sliderValue.round().toString(),
                        onChanged: (double value) {
                          setState(() {
                            sliderValue = value;
                            valueController.text = value.round().toString();
                          });
                        },
                      ),
                    ),
                    Flexible(
                      child: TextFormField(
                        controller: valueController,
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          String newValue =
                              value.replaceAll(",", "").replaceAll(".", "");

                          setState(() {
                            if (newValue.isNotEmpty) {
                              double newSliderValue = double.parse(newValue);
                              if (newSliderValue > 0 && newSliderValue < 900) {
                                sliderValue = newSliderValue;
                              }
                            }
                            valueController.text = newValue;
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: "value",
                          hintText: "123",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 8,
                ),
                TextFormField(
                  controller: noteController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: "Notes reading",
                    hintText: "...",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(
                  height: 32,
                ),
                const Text(
                  "Symptoms of the day",
                  style: TextStyle(fontSize: 18),
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
                  height: 8,
                ),
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
                  height: 32,
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
          await addReading(date, time, sliderValue.round(), noteController.text,
              noteDayController.text, checkboxValues);
          ref.read(entryListProvider.notifier).getEntries();
          Navigator.pop(context);
        },
        label: const Text("SAVE"),
        icon: const Icon(Icons.save),
      ),
    );
  }
}
