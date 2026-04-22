import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peakflow/db/app_database.dart';
import 'package:peakflow/db/prefs.dart';
import 'package:peakflow/models/day_entry_model.dart';
import 'package:peakflow/models/reading_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    debugUseDatabase(null);
  });

  test(
    'migrates legacy shared_preferences readings into drift on first access',
    () async {
      final firstLegacyEntry = _entry(
        date: DateTime(2026, 4, 21),
        note: 'legacy latest',
        readings: [
          _reading(hour: 7, minute: 0, value: 210),
          _reading(hour: 19, minute: 30, value: 380),
        ],
        checkboxValues: const {'Cough': true},
        morningValue: 210,
        eveningValue: 380,
      );
      final secondLegacyEntry = _entry(
        date: DateTime(2026, 4, 19),
        note: 'legacy older',
        readings: [_reading(hour: 8, minute: 15, value: 290)],
        checkboxValues: const {'Unable to work': true},
        morningValue: 290,
        eveningValue: -1,
      );
      final legacyPrefs = {
        'dates': ['20260421', '20260419'],
        '20260421': jsonEncode(firstLegacyEntry.toJson()),
        '20260419': jsonEncode(secondLegacyEntry.toJson()),
      };

      SharedPreferences.setMockInitialValues(legacyPrefs);
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      debugUseDatabase(database, runMigration: true);

      final migratedEntries = await getDayEntries();
      final prefs = await SharedPreferences.getInstance();

      expect(migratedEntries.map((entry) => dateKeyFor(entry.date)).toList(), [
        '20260419',
        '20260421',
      ]);
      expect(migratedEntries.last.note, 'legacy latest');
      expect(
        migratedEntries.last.readings.map((reading) => reading.value).toList(),
        [210, 380],
      );
      expect(migratedEntries.first.checkboxValues['Unable to work'], isTrue);
      expect(prefs.getBool(readingsMigratedToDriftKey), isTrue);
      expect(prefs.getInt(bestValueKey), 380);
    },
  );

  test(
    'keeps existing drift data when migration sees a populated database',
    () async {
      final driftEntry = _entry(
        date: DateTime(2026, 4, 22),
        note: 'already in drift',
        readings: [_reading(hour: 9, minute: 0, value: 410)],
        morningValue: 410,
        eveningValue: -1,
      );
      final legacyEntry = _entry(
        date: DateTime(2026, 4, 18),
        note: 'legacy only',
        readings: [_reading(hour: 6, minute: 45, value: 150)],
        morningValue: 150,
        eveningValue: -1,
      );

      SharedPreferences.setMockInitialValues({
        'dates': ['20260418'],
        '20260418': jsonEncode(legacyEntry.toJson()),
        bestValueKey: 0,
      });

      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      await database.replaceDayEntry(driftEntry);
      debugUseDatabase(database, runMigration: true);

      final entries = await getDayEntries();
      final prefs = await SharedPreferences.getInstance();

      expect(entries, hasLength(1));
      expect(dateKeyFor(entries.single.date), '20260422');
      expect(entries.single.note, 'already in drift');
      expect(entries.single.readings.single.value, 410);
      expect(prefs.getBool(readingsMigratedToDriftKey), isTrue);
      expect(prefs.getInt(bestValueKey), 410);
    },
  );

  test('dedupes duplicate legacy date keys before importing', () async {
    final legacyEntry = _entry(
      date: DateTime(2026, 4, 20),
      note: 'duplicate date entry',
      readings: [
        _reading(hour: 8, minute: 0, value: 275),
        _reading(hour: 18, minute: 15, value: 320),
      ],
      morningValue: 275,
      eveningValue: 320,
    );

    SharedPreferences.setMockInitialValues({
      'dates': ['20260420', '20260420'],
      '20260420': jsonEncode(legacyEntry.toJson()),
    });

    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    debugUseDatabase(database, runMigration: true);

    final entries = await getDayEntries();
    final prefs = await SharedPreferences.getInstance();

    expect(entries, hasLength(1));
    expect(dateKeyFor(entries.single.date), '20260420');
    expect(entries.single.readings.map((reading) => reading.value).toList(), [
      275,
      320,
    ]);
    expect(await database.countStoredDays(), 1);
    expect(prefs.getBool(readingsMigratedToDriftKey), isTrue);
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
