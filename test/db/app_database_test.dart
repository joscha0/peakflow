import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peakflow/db/app_database.dart';
import 'package:peakflow/models/day_entry_model.dart';
import 'package:peakflow/models/reading_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'replaceAllDayEntries stores sorted entries and computes the best value',
    () async {
      final laterEntry = _entry(
        date: DateTime(2026, 4, 21),
        note: 'later',
        readings: [_reading(hour: 18, minute: 30, value: 310, note: 'pm')],
        checkboxValues: const {'Shortness of breath': true},
        morningValue: -1,
        eveningValue: 310,
      );
      final earlierEntry = _entry(
        date: DateTime(2026, 4, 19),
        note: 'earlier',
        readings: [
          _reading(hour: 7, minute: 15, value: 250, note: 'am'),
          _reading(hour: 20, minute: 5, value: 460, note: 'best'),
        ],
        checkboxValues: const {'Cough': true},
        morningValue: 250,
        eveningValue: 460,
      );

      await database.replaceAllDayEntries([laterEntry, earlierEntry]);

      final entries = await database.getAllDayEntries();

      expect(entries.map((entry) => dateKeyFor(entry.date)).toList(), [
        '20260419',
        '20260421',
      ]);
      expect(entries.first.readings.map((reading) => reading.value).toList(), [
        250,
        460,
      ]);
      expect(entries.first.checkboxValues['Cough'], isTrue);
      expect(entries.first.checkboxValues['Unable to work'], isFalse);
      expect(await database.countStoredDays(), 2);
      expect(await database.getBestReadingValue(), 460);
    },
  );

  test(
    'replaceDayEntry overwrites an existing day instead of appending readings',
    () async {
      final date = DateTime(2026, 4, 20);

      await database.replaceDayEntry(
        _entry(
          date: date,
          note: 'first',
          readings: [_reading(hour: 8, minute: 0, value: 200)],
          morningValue: 200,
          eveningValue: -1,
        ),
      );

      await database.replaceDayEntry(
        _entry(
          date: date,
          note: 'updated',
          readings: [_reading(hour: 19, minute: 45, value: 340, note: 'new')],
          checkboxValues: const {'Chest tightness or pain': true},
          morningValue: -1,
          eveningValue: 340,
        ),
      );

      final entry = await database.getDayEntry(date);

      expect(entry, isNotNull);
      expect(entry!.note, 'updated');
      expect(entry.readings, hasLength(1));
      expect(entry.readings.single.value, 340);
      expect(entry.readings.single.time.hour, 19);
      expect(entry.checkboxValues['Chest tightness or pain'], isTrue);
      expect(await database.getBestReadingValue(), 340);
    },
  );

  test('deleteDayEntry removes the day and cascades to its readings', () async {
    final date = DateTime(2026, 4, 18);

    await database.replaceDayEntry(
      _entry(
        date: date,
        readings: [
          _reading(hour: 9, minute: 0, value: 190),
          _reading(hour: 18, minute: 0, value: 280),
        ],
        morningValue: 190,
        eveningValue: 280,
      ),
    );

    await database.deleteDayEntry(date);

    expect(await database.getDayEntry(date), isNull);
    expect(await database.countStoredDays(), 0);
    expect(await database.getBestReadingValue(), 0);
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
