import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:peakflow/providers/day_entries_provider.dart';
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
  int maxVolume = 850;
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
    loadMax();
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

  void loadMax() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      maxVolume = prefs.getInt("maxVolume") ?? 850;
    });
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
                        max: maxVolume.toDouble(),
                        divisions: maxVolume ~/ 50,
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
                          setState(() {
                            if (value.isNotEmpty) {
                              double newSliderValue = double.parse(value);
                              if (newSliderValue > 0 &&
                                  newSliderValue < maxVolume) {
                                sliderValue = newSliderValue;
                              }
                            }
                          });
                        },
                        inputFormatters: [
                          FilteringTextInputFormatter(RegExp(r'[0-9]'),
                              allow: true),
                        ],
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
