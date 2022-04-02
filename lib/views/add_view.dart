import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:peakflow/db/day_entries_provider.dart';
import 'package:peakflow/db/prefs.dart';

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

  void pickDate(BuildContext context) async {
    date = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime.now().add(const Duration(days: -100)),
            lastDate: DateTime.now()) ??
        DateTime.now();

    setState(() {});
  }

  void pickTime(BuildContext context) async {
    time =
        await showTimePicker(context: context, initialTime: TimeOfDay.now()) ??
            TimeOfDay.now();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add reading"),
      ),
      body: Form(
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
                  labelText: "Note",
                  hintText: "...",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
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
              date, time, sliderValue.round(), noteController.text);
          ref.read(entryListProvider.notifier).getEntries();
          Navigator.pop(context);
        },
        label: const Text("SAVE"),
        icon: const Icon(Icons.save),
      ),
    );
  }
}
