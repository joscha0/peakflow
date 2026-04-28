import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:peakflow/global/consts.dart';
import 'package:peakflow/models/day_entry_model.dart';
import 'package:peakflow/models/reading_model.dart';

part 'app_database.g.dart';

class StoredDays extends Table {
  TextColumn get dateKey => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get note => text().withDefault(const Constant(''))();
  IntColumn get morningValue => integer().withDefault(const Constant(-1))();
  IntColumn get eveningValue => integer().withDefault(const Constant(-1))();
  TextColumn get checkboxValuesJson =>
      text().withDefault(const Constant('{}'))();

  @override
  Set<Column<Object>> get primaryKey => {dateKey};
}

class StoredReadings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get dayDateKey =>
      text().references(StoredDays, #dateKey, onDelete: KeyAction.cascade)();
  IntColumn get hour => integer()();
  IntColumn get minute => integer()();
  IntColumn get value => integer()();
  TextColumn get note => text().withDefault(const Constant(''))();
}

@DriftDatabase(tables: [StoredDays, StoredReadings])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(
        executor ??
            driftDatabase(
              name: 'peakflow_readings',
              web: DriftWebOptions(
                sqlite3Wasm: Uri.parse('sqlite3.wasm'),
                driftWorker: Uri.parse('drift_worker.js'),
              ),
            ),
      );

  @override
  int get schemaVersion => 1;

  Future<int> countStoredDays() async {
    final countExpression = storedDays.dateKey.count();
    final query = selectOnly(storedDays)..addColumns([countExpression]);
    final row = await query.getSingle();
    return row.read(countExpression) ?? 0;
  }

  Future<int> getBestReadingValue() async {
    final maxExpression = storedReadings.value.max();
    final query = selectOnly(storedReadings)..addColumns([maxExpression]);
    final row = await query.getSingle();
    return row.read(maxExpression) ?? 0;
  }

  Future<List<DayEntry>> getAllDayEntries() async {
    final dayRows = await (select(
      storedDays,
    )..orderBy([(table) => OrderingTerm.asc(table.date)])).get();
    final readingRows =
        await (select(storedReadings)..orderBy([
              (table) => OrderingTerm.asc(table.dayDateKey),
              (table) => OrderingTerm.asc(table.hour),
              (table) => OrderingTerm.asc(table.minute),
              (table) => OrderingTerm.asc(table.id),
            ]))
            .get();

    return _toDayEntries(dayRows, readingRows);
  }

  Future<DayEntry?> getDayEntry(DateTime date) {
    return getDayEntryByKey(dateKeyFor(date));
  }

  Future<DayEntry?> getDayEntryByKey(String key) async {
    final dayRow = await (select(
      storedDays,
    )..where((table) => table.dateKey.equals(key))).getSingleOrNull();
    if (dayRow == null) {
      return null;
    }

    final readingRows =
        await ((select(storedReadings)
                ..where((table) => table.dayDateKey.equals(key)))
              ..orderBy([
                (table) => OrderingTerm.asc(table.hour),
                (table) => OrderingTerm.asc(table.minute),
                (table) => OrderingTerm.asc(table.id),
              ]))
            .get();

    return _toDayEntry(dayRow, readingRows);
  }

  Future<void> replaceAllDayEntries(List<DayEntry> entries) async {
    await transaction(() async {
      await delete(storedReadings).go();
      await delete(storedDays).go();

      if (entries.isEmpty) {
        return;
      }

      await batch((batch) {
        batch.insertAll(
          storedDays,
          entries.map(_storedDayCompanion).toList(growable: false),
        );

        final readingCompanions = <StoredReadingsCompanion>[
          for (final entry in entries)
            for (final reading in entry.readings)
              _storedReadingCompanion(
                dateKey: dateKeyFor(entry.date),
                reading: reading,
              ),
        ];

        if (readingCompanions.isNotEmpty) {
          batch.insertAll(storedReadings, readingCompanions);
        }
      });
    });
  }

  Future<void> replaceDayEntry(DayEntry entry) async {
    final key = dateKeyFor(entry.date);

    await transaction(() async {
      await into(storedDays).insertOnConflictUpdate(_storedDayCompanion(entry));
      await (delete(
        storedReadings,
      )..where((table) => table.dayDateKey.equals(key))).go();

      if (entry.readings.isNotEmpty) {
        await batch((batch) {
          batch.insertAll(
            storedReadings,
            entry.readings
                .map(
                  (reading) =>
                      _storedReadingCompanion(dateKey: key, reading: reading),
                )
                .toList(growable: false),
          );
        });
      }
    });
  }

  Future<void> deleteDayEntry(DateTime date) async {
    final key = dateKeyFor(date);

    await transaction(() async {
      await (delete(
        storedReadings,
      )..where((table) => table.dayDateKey.equals(key))).go();
      await (delete(
        storedDays,
      )..where((table) => table.dateKey.equals(key))).go();
    });
  }

  StoredDaysCompanion _storedDayCompanion(DayEntry entry) {
    return StoredDaysCompanion.insert(
      dateKey: dateKeyFor(entry.date),
      date: entry.date,
      note: Value(entry.note),
      morningValue: Value(entry.morningValue),
      eveningValue: Value(entry.eveningValue),
      checkboxValuesJson: Value(jsonEncode(entry.checkboxValues)),
    );
  }

  StoredReadingsCompanion _storedReadingCompanion({
    required String dateKey,
    required Reading reading,
  }) {
    return StoredReadingsCompanion.insert(
      dayDateKey: dateKey,
      hour: reading.time.hour,
      minute: reading.time.minute,
      value: reading.value,
      note: Value(reading.note),
    );
  }

  List<DayEntry> _toDayEntries(
    List<StoredDay> dayRows,
    List<StoredReading> readingRows,
  ) {
    final readingsByDay = <String, List<StoredReading>>{};
    for (final reading in readingRows) {
      readingsByDay.putIfAbsent(reading.dayDateKey, () => []).add(reading);
    }

    return dayRows
        .map((day) => _toDayEntry(day, readingsByDay[day.dateKey] ?? const []))
        .toList(growable: false);
  }

  DayEntry _toDayEntry(StoredDay day, List<StoredReading> readingRows) {
    final storedCheckboxValues = _decodeCheckboxValues(day.checkboxValuesJson);
    return DayEntry(
      date: day.date,
      readings: readingRows
          .map(
            (reading) => Reading(
              time: TimeOfDay(hour: reading.hour, minute: reading.minute),
              value: reading.value,
              note: reading.note,
            ),
          )
          .toList(growable: false),
      note: day.note,
      morningValue: day.morningValue,
      eveningValue: day.eveningValue,
      checkboxValues: {...defaultCheckboxValues, ...storedCheckboxValues},
    );
  }

  Map<String, bool> _decodeCheckboxValues(String checkboxValuesJson) {
    final decoded = jsonDecode(checkboxValuesJson);
    if (decoded is! Map<String, dynamic>) {
      return Map<String, bool>.from(defaultCheckboxValues);
    }

    return decoded.map((key, value) => MapEntry(key, value == true));
  }
}

String dateKeyFor(DateTime date) {
  final normalizedDate = DateTime(date.year, date.month, date.day);
  final month = normalizedDate.month.toString().padLeft(2, '0');
  final day = normalizedDate.day.toString().padLeft(2, '0');
  return '${normalizedDate.year}$month$day';
}
