import 'package:peakflow/models/reading_model.dart';

class DayEntry {
  final DateTime date;
  final List<Reading> readings;
  final String note;
  final int morningValue;
  final int eveningValue;
  // final bool cough;
  // final bool coughNight;
  // final bool wheezingBreathing;
  // final bool breathlessness;
  // final bool heavyBreathing;
  // final bool painInTheChest;
  // final bool unableToWork;

  const DayEntry({
    required this.date,
    required this.readings,
    required this.note,
    required this.morningValue,
    required this.eveningValue,
    // required this.cough,
    // required this.coughNight,
    // required this.wheezingBreathing,
    // required this.breathlessness,
    // required this.heavyBreathing,
    // required this.painInTheChest,
    // required this.unableToWork,
  });

  DayEntry.fromJson(Map<String, dynamic> json)
      : date = DateTime.parse(json['date']),
        readings = (json['readings'] as List)
            .map((item) => Reading.fromJson(item))
            .toList(),
        note = json['note'],
        morningValue = json['morningValue'],
        eveningValue = json['eveningValue'];

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'readings': readings.map((item) => item.toJson()).toList(),
      'note': note,
      'morningValue': morningValue,
      'eveningValue': eveningValue
    };
  }
}
