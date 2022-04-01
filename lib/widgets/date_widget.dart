import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateWidget extends StatelessWidget {
  final DateTime date;
  final int? morningValue;
  final int? eveningValue;
  final int bestValue;

  const DateWidget({
    Key? key,
    required this.date,
    this.morningValue,
    this.eveningValue,
    required this.bestValue,
  }) : super(key: key);

  Color getColor(int value) {
    if (value > bestValue * 0.8) {
      return Colors.green;
    } else if (value < bestValue * 0.5) {
      return Colors.red;
    } else {
      return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(children: [
          Text(
            DateFormat("d").format(date),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          Text(DateFormat("MM.yyyy").format(date)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (morningValue != null) ...[
                Column(
                  children: [
                    Icon(
                      Icons.light_mode,
                      color: getColor(morningValue!),
                    ),
                    Text(
                      morningValue.toString(),
                      style: TextStyle(
                        color: getColor(morningValue!),
                      ),
                    ),
                  ],
                ),
              ],
              if (eveningValue != null) ...[
                Column(
                  children: [
                    Icon(
                      Icons.nights_stay,
                      color: getColor(eveningValue!),
                    ),
                    Text(
                      eveningValue.toString(),
                      style: TextStyle(
                        color: getColor(eveningValue!),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ]),
      ),
    );
  }
}
