import 'package:flutter/material.dart';
import 'package:peakflow/models/day_entry_model.dart';
import 'package:peakflow/models/reading_model.dart';

DayEntry buildDayEntry({
  required DateTime date,
  required List<Reading> readings,
  String note = '',
  Map<String, bool> checkboxValues = const {},
  int morningValue = -1,
  int eveningValue = -1,
}) {
  return DayEntry(
    date: date,
    readings: readings,
    note: note,
    morningValue: morningValue,
    eveningValue: eveningValue,
    checkboxValues: checkboxValues,
  );
}

Reading buildReading({
  required int hour,
  required int minute,
  required int value,
  String note = '',
}) {
  return Reading(
    time: TimeOfDay(hour: hour, minute: minute),
    value: value,
    note: note,
  );
}
