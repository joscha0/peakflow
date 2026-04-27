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

  test('replace import removes days that are only stored locally', () async {
    await importDayEntriesJson(
      encodeDayEntriesJsonBackup([
        _entry(
          date: DateTime(2026, 4, 20),
          readings: [_reading(hour: 8, minute: 0, value: 310)],
          morningValue: 310,
        ),
        _entry(
          date: DateTime(2026, 4, 21),
          readings: [_reading(hour: 8, minute: 0, value: 320)],
          morningValue: 320,
        ),
      ]),
    );

    await importDayEntriesJson(
      encodeDayEntriesJsonBackup([
        _entry(
          date: DateTime(2026, 4, 21),
          readings: [_reading(hour: 9, minute: 0, value: 430)],
          morningValue: 430,
        ),
      ]),
    );

    final entries = await getDayEntries();

    expect(entries, hasLength(1));
    expect(entries.single.date, DateTime(2026, 4, 21));
    expect(entries.single.readings.single.value, 430);
    expect(await getBestValue(), 430);
  });

  test('previews merge impact before importing a JSON backup', () async {
    await importDayEntriesJson(
      encodeDayEntriesJsonBackup([
        _entry(
          date: DateTime(2026, 4, 20),
          readings: [_reading(hour: 7, minute: 0, value: 360)],
          morningValue: 360,
        ),
        _entry(
          date: DateTime(2026, 4, 21),
          note: 'local note',
          readings: [
            _reading(hour: 8, minute: 0, value: 300, note: 'same'),
            _reading(hour: 20, minute: 0, value: 420),
          ],
          checkboxValues: const {'Cough': true},
          morningValue: 300,
          eveningValue: 420,
        ),
      ]),
    );

    final backup = encodeDayEntriesJsonBackup([
      _entry(
        date: DateTime(2026, 4, 21),
        note: 'backup note',
        readings: [
          _reading(hour: 8, minute: 0, value: 300, note: 'same'),
          _reading(hour: 9, minute: 30, value: 330),
        ],
        checkboxValues: const {'Wheezing breathing': true},
        morningValue: 315,
        eveningValue: -1,
      ),
      _entry(
        date: DateTime(2026, 4, 22),
        readings: [_reading(hour: 18, minute: 15, value: 510)],
        morningValue: -1,
        eveningValue: 510,
      ),
    ]);

    final preview = await previewDayEntriesJsonImport(backup);

    expect(preview.currentDays, 2);
    expect(preview.currentReadings, 3);
    expect(preview.backupDays, 2);
    expect(preview.backupReadings, 3);
    expect(preview.currentOnlyDays, 1);
    expect(preview.backupOnlyDays, 1);
    expect(preview.overlappingDays, 1);
    expect(preview.daysChangedByMerge, 2);
    expect(preview.newReadings, 2);
    expect(preview.duplicateReadings, 1);
    expect(preview.newSymptomValues, 1);
    expect(preview.dayNoteConflicts, 1);
    expect(preview.daysAfterMerge, 3);
  });

  test('merges a JSON backup without replacing newer local data', () async {
    await importDayEntriesJson(
      encodeDayEntriesJsonBackup([
        _entry(
          date: DateTime(2026, 4, 20),
          readings: [_reading(hour: 7, minute: 0, value: 360)],
          morningValue: 360,
        ),
        _entry(
          date: DateTime(2026, 4, 21),
          note: 'local note',
          readings: [
            _reading(hour: 8, minute: 0, value: 300, note: 'same'),
            _reading(hour: 20, minute: 0, value: 420),
          ],
          checkboxValues: const {'Cough': true},
          morningValue: 300,
          eveningValue: 420,
        ),
      ]),
    );

    final mergeResult = await mergeDayEntriesJson(
      encodeDayEntriesJsonBackup([
        _entry(
          date: DateTime(2026, 4, 21),
          note: 'backup note',
          readings: [
            _reading(hour: 8, minute: 0, value: 300, note: 'same'),
            _reading(hour: 9, minute: 30, value: 330),
          ],
          checkboxValues: const {'Wheezing breathing': true},
          morningValue: 315,
          eveningValue: -1,
        ),
        _entry(
          date: DateTime(2026, 4, 22),
          readings: [_reading(hour: 18, minute: 15, value: 510)],
          morningValue: -1,
          eveningValue: 510,
        ),
      ]),
    );

    final entries = await getDayEntries();
    final mergedDay = entries.firstWhere(
      (entry) => entry.date == DateTime(2026, 4, 21),
    );

    expect(mergeResult.newReadings, 2);
    expect(entries, hasLength(3));
    expect(mergedDay.note, 'local note');
    expect(mergedDay.readings.map((reading) => reading.value), [300, 330, 420]);
    expect(mergedDay.checkboxValues['Cough'], isTrue);
    expect(mergedDay.checkboxValues['Wheezing breathing'], isTrue);
    expect(mergedDay.morningValue, 315);
    expect(mergedDay.eveningValue, 420);
    expect(await getBestValue(), 510);
  });

  test(
    'merge skips exact duplicate readings without changing local data',
    () async {
      final entry = _entry(
        date: DateTime(2026, 4, 21),
        note: 'local note',
        readings: [_reading(hour: 8, minute: 0, value: 300, note: 'same')],
        checkboxValues: const {'Cough': true},
        morningValue: 300,
      );
      final backup = encodeDayEntriesJsonBackup([entry]);

      await importDayEntriesJson(backup);

      final preview = await previewDayEntriesJsonImport(backup);
      final mergeResult = await mergeDayEntriesJson(backup);
      final entries = await getDayEntries();

      expect(preview.newReadings, 0);
      expect(preview.duplicateReadings, 1);
      expect(preview.daysChangedByMerge, 0);
      expect(mergeResult.newReadings, 0);
      expect(entries, hasLength(1));
      expect(entries.single.readings, hasLength(1));
      expect(entries.single.note, 'local note');
      expect(entries.single.checkboxValues['Cough'], isTrue);
    },
  );

  test('merge fills an empty local day note from the backup', () async {
    await importDayEntriesJson(
      encodeDayEntriesJsonBackup([
        _entry(
          date: DateTime(2026, 4, 21),
          readings: [_reading(hour: 8, minute: 0, value: 300)],
          morningValue: 300,
        ),
      ]),
    );

    final backup = encodeDayEntriesJsonBackup([
      _entry(
        date: DateTime(2026, 4, 21),
        note: 'backup note',
        readings: [_reading(hour: 8, minute: 0, value: 300)],
        morningValue: 300,
      ),
    ]);

    final preview = await previewDayEntriesJsonImport(backup);
    await mergeDayEntriesJson(backup);
    final entries = await getDayEntries();

    expect(preview.newDayNotes, 1);
    expect(preview.dayNoteConflicts, 0);
    expect(entries.single.note, 'backup note');
    expect(entries.single.readings, hasLength(1));
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
