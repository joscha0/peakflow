import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:peakflow/db/prefs.dart';
import 'package:peakflow/models/day_entry_model.dart';
import 'package:peakflow/models/reading_model.dart';
import 'package:peakflow/providers/day_entries_provider.dart';
import 'package:peakflow/views/day_view.dart';

class EditReadingView extends StatefulHookConsumerWidget {
  final Reading reading;
  final DayEntry dayEntry;
  final int readingIndex;

  const EditReadingView(
      {Key? key,
      required this.reading,
      required this.readingIndex,
      required this.dayEntry})
      : super(key: key);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _EditReadingViewState();
}

class _EditReadingViewState extends ConsumerState<EditReadingView> {
  late TimeOfDay time;
  double sliderValue = 0;
  int maxVolume = 850;
  final valueController = TextEditingController();
  final noteController = TextEditingController();

  void pickTime(BuildContext context) async {
    time = await showTimePicker(context: context, initialTime: time) ?? time;
    setState(() {});
  }

  @override
  void initState() {
    time = widget.reading.time;
    sliderValue = widget.reading.value.toDouble();
    valueController.text = widget.reading.value.toString();
    noteController.text = widget.reading.note;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(
              "Edit reading ${widget.reading.time.format(context)} - ${DateFormat("dd.MM.yyyy").format(widget.dayEntry.date)} ")),
      body: SingleChildScrollView(
          child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              children: [
                const Text("Time: "),
                TextButton(
                    onPressed: () {
                      pickTime(context);
                    },
                    child: Text(time.format(context))),
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
          ],
        ),
      )),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          DayEntry newEntry = await updateReading(
              widget.dayEntry,
              Reading(
                  time: time,
                  value: int.parse(valueController.text),
                  note: noteController.text),
              widget.readingIndex);
          int bestValue = await getBestValue();
          ref.read(entryListProvider.notifier).loadEntries();
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
