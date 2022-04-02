import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:peakflow/global/helper.dart';
import 'package:peakflow/models/day_entry_model.dart';
import 'package:peakflow/models/reading_model.dart';

class DayView extends StatefulHookConsumerWidget {
  const DayView({Key? key, required this.dayEntry, required this.bestValue})
      : super(key: key);

  final DayEntry dayEntry;
  final int bestValue;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _DayViewState();
}

class _DayViewState extends ConsumerState<DayView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat("dd.MM.yyyy").format(widget.dayEntry.date)),
      ),
      body: Column(children: [
        for (Reading reading in widget.dayEntry.readings) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
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
                          color: getColor(reading.value, widget.bestValue),
                        ),
                        Text(
                          reading.value.toString(),
                          style: TextStyle(
                            fontSize: 24,
                            color: getColor(reading.value, widget.bestValue),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: Column(
                      children: [
                        Text(reading.time.format(context)),
                        Text("note"),
                      ],
                    ),
                  ),
                  Flexible(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ExpandIcon(onPressed: (_) {}),
                        PopupMenuButton(itemBuilder: (_) {
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
                        })
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        ]
      ]),
    );
  }
}
