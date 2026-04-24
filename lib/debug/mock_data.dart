import 'package:flutter/material.dart';
import 'package:peakflow/models/day_entry_model.dart';
import 'package:peakflow/models/reading_model.dart';

const int defaultMockEntryCount = 120;
const int minMockEntryCount = 1;
const int maxMockEntryCount = 2000;

List<DayEntry> buildMockDayEntries({int count = defaultMockEntryCount}) {
  final normalizedCount = count
      .clamp(minMockEntryCount, maxMockEntryCount)
      .toInt();
  final entries = <DayEntry>[];
  var currentDate = DateTime(2026, 4, 20);

  for (var index = 0; index < normalizedCount; index++) {
    entries.add(_buildEntry(index, currentDate));
    currentDate = DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day - _gapAfter(index),
    );
  }

  return entries.reversed.toList(growable: false);
}

DayEntry _buildEntry(int index, DateTime date) {
  final readings = _buildReadings(index);
  final morningValue = _average(
    readings.where((reading) => reading.time.hour < 12),
  );
  final eveningValue = _average(
    readings.where((reading) => reading.time.hour >= 12),
  );

  return DayEntry(
    date: date,
    readings: readings,
    note: _buildDayNote(index),
    morningValue: morningValue,
    eveningValue: eveningValue,
    checkboxValues: _checkboxValues(index),
  );
}

List<Reading> _buildReadings(int index) {
  final readings = <Reading>[
    _reading(
      hour: 6 + (index % 3),
      minute: (index * 7) % 60,
      value: 250 + ((index * 17) % 170),
      note: _readingNote(index, 0),
    ),
  ];

  if (index % 5 != 1) {
    readings.add(
      _reading(
        hour: 12 + (index % 5),
        minute: (index * 11) % 60,
        value: 270 + ((index * 19 + 35) % 180),
        note: _readingNote(index, 1),
      ),
    );
  }

  if (index % 4 == 0 || index % 9 == 0) {
    readings.add(
      _reading(
        hour: 18 + (index % 3),
        minute: (index * 13) % 60,
        value: 300 + ((index * 23 + 20) % 150),
        note: _readingNote(index, 2),
      ),
    );
  }

  return readings;
}

int _average(Iterable<Reading> readings) {
  final values = readings
      .map((reading) => reading.value)
      .toList(growable: false);
  if (values.isEmpty) {
    return -1;
  }

  final sum = values.fold<int>(0, (total, value) => total + value);
  return (sum / values.length).round();
}

int _gapAfter(int index) {
  if (index % 14 == 0) {
    return 9;
  }
  if (index % 6 == 0) {
    return 4;
  }
  if (index.isEven) {
    return 2;
  }
  return 1;
}

String _buildDayNote(int index) {
  const dayNotes = [
    'Cold air made the morning feel tighter than usual.',
    'Symptoms settled after rest and hydration.',
    'Exercise felt okay, but the evening reading dipped a bit.',
    'Work stress seemed to make breathing more noticeable.',
    'Mostly steady day with a better rhythm by the evening.',
    'Allergies were noticeable after being outside.',
    'Sleep was rough and the first reading came in lower.',
    'Medication helped and readings recovered later in the day.',
  ];

  return '${dayNotes[index % dayNotes.length]} Debug sample ${index + 1}.';
}

String _readingNote(int index, int readingIndex) {
  const readingNotes = [
    'before medication',
    'after a short walk',
    'after inhaler',
    'during allergy symptoms',
    'steady breathing',
    'slightly tight chest',
  ];

  return readingNotes[(index + readingIndex) % readingNotes.length];
}

Map<String, bool> _checkboxValues(int index) {
  const symptoms = [
    'Cough',
    'Cough night',
    'Wheezing breathing',
    'Shortness of breath',
    'Difficult breathing',
    'Chest tightness or pain',
    'Unable to work',
  ];

  final values = <String, bool>{};
  for (var symptomIndex = 0; symptomIndex < symptoms.length; symptomIndex++) {
    final symptom = symptoms[symptomIndex];
    final isActive = (index + symptomIndex * 3) % (symptomIndex + 4) == 0;
    values[symptom] = isActive;
  }

  if (!values.containsValue(true)) {
    values[symptoms[index % symptoms.length]] = true;
  }

  return values;
}

Reading _reading({
  required int hour,
  required int minute,
  required int value,
  required String note,
}) {
  return Reading(
    time: TimeOfDay(hour: hour, minute: minute),
    value: value,
    note: note,
  );
}
