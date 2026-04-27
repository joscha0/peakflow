import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peakflow/db/prefs.dart';
import 'package:peakflow/models/day_entry_model.dart';
import 'package:peakflow/models/reading_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_helpers/widget_test_setup.dart';

void main() {
  setUpWidgetTestDatabase();

  test('encodes day entries as a restorable Peak Flow JSON backup', () {
    final entry = _entry(
      date: DateTime(2026, 4, 21),
      note: 'windy day',
      readings: [_reading(hour: 8, minute: 15, value: 420, note: 'steady')],
      checkboxValues: const {'Cough': true},
      morningValue: 420,
      eveningValue: -1,
    );

    final backup = encodeDayEntriesJsonBackup([entry]);
    final decoded = jsonDecode(backup) as Map<String, dynamic>;

    expect(decoded['format'], 'peakflow.backup');
    expect(decoded['version'], 1);
    expect(decoded['entries'], hasLength(1));
    expect(decoded['entries'][0]['note'], 'windy day');
    expect(decoded['entries'][0]['readings'][0]['value'], 420);
  });

  test('imports a JSON backup and replaces existing local entries', () async {
    await debugLoadMockData(count: 3);
    expect(await getDayEntries(), hasLength(3));

    final importedEntry = _entry(
      date: DateTime(2026, 4, 22),
      note: 'imported',
      readings: [_reading(hour: 19, minute: 45, value: 510)],
      checkboxValues: const {'Wheezing breathing': true},
      morningValue: -1,
      eveningValue: 510,
    );

    final importedCount = await importDayEntriesJson(
      encodeDayEntriesJsonBackup([importedEntry]),
    );

    final entries = await getDayEntries();
    final prefs = await SharedPreferences.getInstance();

    expect(importedCount, 1);
    expect(entries, hasLength(1));
    expect(entries.single.note, 'imported');
    expect(entries.single.readings.single.value, 510);
    expect(await getBestValue(), 510);
    expect(prefs.getBool(readingsMigratedToDriftKey), isTrue);
  });

  test('decodes a legacy list-shaped JSON export', () {
    final entry = _entry(
      date: DateTime(2026, 4, 23),
      readings: [_reading(hour: 7, minute: 30, value: 390)],
      morningValue: 390,
    );

    final entries = decodeDayEntriesJsonBackup(jsonEncode([entry.toJson()]));

    expect(entries, hasLength(1));
    expect(entries.single.readings.single.value, 390);
  });

  test('rejects JSON without backup entries', () {
    expect(
      () => decodeDayEntriesJsonBackup('{"format":"peakflow.backup"}'),
      throwsFormatException,
    );
  });
}

DayEntry _entry({
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

Reading _reading({
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
