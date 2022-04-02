import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:peakflow/global/helper.dart';
import 'package:peakflow/models/day_entry_model.dart';
import 'package:peakflow/views/day_view.dart';

class DateWidget extends StatelessWidget {
  final DayEntry dayEntry;
  final int bestValue;

  const DateWidget({
    Key? key,
    required this.dayEntry,
    required this.bestValue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[900],
      child: InkWell(
        onTap: (() {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => DayView(
                    dayEntry: dayEntry,
                    bestValue: bestValue,
                  )));
        }),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(children: [
            Text(
              DateFormat("d").format(dayEntry.date),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            Text(DateFormat("MM.yyyy").format(dayEntry.date)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (dayEntry.morningValue != null &&
                    dayEntry.morningValue != -1) ...[
                  Column(
                    children: [
                      Icon(
                        Icons.light_mode,
                        color: getColor(dayEntry.morningValue, bestValue),
                      ),
                      Text(
                        dayEntry.morningValue.toString(),
                        style: TextStyle(
                          color: getColor(dayEntry.morningValue, bestValue),
                        ),
                      ),
                    ],
                  ),
                ],
                if (dayEntry.eveningValue != null &&
                    dayEntry.eveningValue != -1) ...[
                  Column(
                    children: [
                      Icon(
                        Icons.nights_stay,
                        color: getColor(dayEntry.eveningValue, bestValue),
                      ),
                      Text(
                        dayEntry.eveningValue.toString(),
                        style: TextStyle(
                          color: getColor(dayEntry.eveningValue, bestValue),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ]),
        ),
      ),
    );
  }
}
