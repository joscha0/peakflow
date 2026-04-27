import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:peakflow/db/app_database.dart';
import 'package:peakflow/debug/mock_data.dart';
import 'package:peakflow/models/day_entry_model.dart';
import 'package:peakflow/models/reading_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

const int defaultMaxVolume = 850;
const String maxVolumeKey = "maxVolume";
const String bestValueKey = "bestValue";
const String useAutomaticMaxValueKey = "useAutomaticMaxValue";
const String manualColorReferenceMaxValueKey = "manualColorReferenceMaxValue";
const String readingsMigratedToDriftKey = "readingsMigratedToDrift";

Future<AppDatabase>? _databaseFuture;

Future<int> getBestValue() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt(bestValueKey) ?? 0;
}

Future<int> getDeviceMaxValue() async {
  final prefs = await SharedPreferences.getInstance();
  return _sanitizeMaxValue(prefs.getInt(maxVolumeKey));
}

Future<void> setDeviceMaxValue(int value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(maxVolumeKey, _sanitizeMaxValue(value));
}

Future<int> getManualColorReferenceMaxValue() async {
  final prefs = await SharedPreferences.getInstance();
  final storedValue =
      prefs.getInt(manualColorReferenceMaxValueKey) ??
      prefs.getInt(maxVolumeKey);
  return _sanitizeMaxValue(storedValue);
}

Future<void> setManualColorReferenceMaxValue(int value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(manualColorReferenceMaxValueKey, _sanitizeMaxValue(value));
}

Future<bool> getUseAutomaticMaxValue() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(useAutomaticMaxValueKey) ?? true;
}

Future<void> setUseAutomaticMaxValue(bool value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(useAutomaticMaxValueKey, value);
}

Future<int> getColorReferenceMaxValue() async {
  final prefs = await SharedPreferences.getInstance();
  final manualMaxValue = _sanitizeMaxValue(
    prefs.getInt(manualColorReferenceMaxValueKey) ?? prefs.getInt(maxVolumeKey),
  );
  final useAutomaticMaxValue = prefs.getBool(useAutomaticMaxValueKey) ?? true;

  if (!useAutomaticMaxValue) {
    return manualMaxValue;
  }

  final bestValue = prefs.getInt(bestValueKey) ?? 0;
  return bestValue > 0 ? bestValue : manualMaxValue;
}

Future<void> setBestValue(int value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(bestValueKey, value);
}

Future<void> updateBestValue() async {
  final database = await _getDatabase();
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(bestValueKey, await database.getBestReadingValue());
}

Future<List<DayEntry>> getDayEntries() async {
  final database = await _getDatabase();
  return database.getAllDayEntries();
}

String encodeDayEntriesJsonBackup(List<DayEntry> entries) {
  final backup = {
    'format': 'peakflow.backup',
    'version': 1,
    'exportedAt': DateTime.now().toUtc().toIso8601String(),
    'entries': entries.map((entry) => entry.toJson()).toList(),
  };

  return const JsonEncoder.withIndent('  ').convert(backup);
}

List<DayEntry> decodeDayEntriesJsonBackup(String data) {
  final decoded = jsonDecode(data);
  final Object? rawEntries;

  if (decoded is List) {
    rawEntries = decoded;
  } else if (decoded is Map<String, dynamic>) {
    rawEntries = decoded['entries'] ?? decoded['dayEntries'];
  } else {
    throw const FormatException('Backup JSON must be an object or list.');
  }

  if (rawEntries is! List) {
    throw const FormatException('Backup JSON does not contain entries.');
  }

  return rawEntries
      .map((entry) {
        if (entry is! Map<String, dynamic>) {
          throw const FormatException('Every backup entry must be an object.');
        }
        return DayEntry.fromJson(entry);
      })
      .toList(growable: false);
}

Future<String> exportDayEntriesJson() async {
  return encodeDayEntriesJsonBackup(await getDayEntries());
}

Future<int> importDayEntriesJson(String data) async {
  final entries = decodeDayEntriesJsonBackup(data);
  final database = await _getDatabase();
  await database.replaceAllDayEntries(entries);
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(readingsMigratedToDriftKey, true);
  await prefs.setInt(bestValueKey, await database.getBestReadingValue());
  return entries.length;
}

Future<DayEntry?> getDayEntry(DateTime date) async {
  final database = await _getDatabase();
  return database.getDayEntry(date);
}

Future<DayEntry> addReading(
  DateTime date,
  TimeOfDay time,
  int value,
  String noteReading,
  String noteDay,
  Map<String, bool> checkboxValues,
) async {
  final database = await _getDatabase();
  final existingEntry = await database.getDayEntry(date);
  final readings = List<Reading>.from(existingEntry?.readings ?? const []);
  readings.add(Reading(time: time, value: value, note: noteReading));

  final morningEvening = getMorningEveningValue(readings);
  final newEntry = DayEntry(
    date: existingEntry?.date ?? date,
    readings: readings,
    note: noteDay,
    morningValue: morningEvening[0],
    eveningValue: morningEvening[1],
    checkboxValues: checkboxValues,
  );

  await database.replaceDayEntry(newEntry);
  await _storeBestValueAfterWrite(database, fallbackCandidate: value);
  return newEntry;
}

int _sanitizeMaxValue(int? value) {
  if (value == null || value <= 0) {
    return defaultMaxVolume;
  }
  return value;
}

Future<void> deleteReading(DateTime date, int readingIndex) async {
  final database = await _getDatabase();
  final entry = await database.getDayEntry(date);
  if (entry == null || readingIndex >= entry.readings.length) {
    return;
  }

  final updatedReadings = List<Reading>.from(entry.readings)
    ..removeAt(readingIndex);
  final morningEvening = getMorningEveningValue(updatedReadings);
  final newEntry = DayEntry(
    date: entry.date,
    readings: updatedReadings,
    note: entry.note,
    morningValue: morningEvening[0],
    eveningValue: morningEvening[1],
    checkboxValues: entry.checkboxValues,
  );

  await database.replaceDayEntry(newEntry);
  await _storeBestValueAfterWrite(database);
}

List<int> getMorningEveningValue(List<Reading> readings) {
  int morningSum = 0;
  int morningCount = 0;
  int eveningSum = 0;
  int eveningCount = 0;
  for (Reading reading in readings) {
    if (reading.time.hour < 12) {
      morningSum += reading.value;
      morningCount++;
    } else {
      eveningSum += reading.value;
      eveningCount++;
    }
  }
  List<int> morningEvening = [];
  morningEvening.add(
    morningCount >= 1 ? (morningSum / morningCount).round() : -1,
  );
  morningEvening.add(
    eveningCount >= 1 ? (eveningSum / eveningCount).round() : -1,
  );
  return morningEvening;
}

Future<void> deleteDay(DateTime date) async {
  final database = await _getDatabase();
  await database.deleteDayEntry(date);
  await _storeBestValueAfterWrite(database);
}

Future<DayEntry> updateDay(
  DayEntry dayEntry,
  String note,
  Map<String, bool> checkboxValues,
) async {
  final database = await _getDatabase();
  final newEntry = DayEntry(
    date: dayEntry.date,
    readings: dayEntry.readings,
    note: note,
    morningValue: dayEntry.morningValue,
    eveningValue: dayEntry.eveningValue,
    checkboxValues: checkboxValues,
  );

  await database.replaceDayEntry(newEntry);
  return newEntry;
}

Future<DayEntry> updateReading(
  DayEntry dayEntry,
  Reading reading,
  int readingIndex,
) async {
  await deleteReading(dayEntry.date, readingIndex);
  return await addReading(
    dayEntry.date,
    reading.time,
    reading.value,
    reading.note,
    dayEntry.note,
    dayEntry.checkboxValues,
  );
}

Future<AppDatabase> _getDatabase() {
  return _databaseFuture ??= _openDatabase();
}

Future<AppDatabase> _openDatabase() async {
  final database = AppDatabase();
  await _migrateReadingsToDriftIfNeeded(database);
  return database;
}

Future<void> _migrateReadingsToDriftIfNeeded(AppDatabase database) async {
  final prefs = await SharedPreferences.getInstance();
  final migrationDone = prefs.getBool(readingsMigratedToDriftKey) ?? false;
  if (migrationDone) {
    return;
  }

  final existingRows = await database.countStoredDays();
  if (existingRows > 0) {
    await prefs.setBool(readingsMigratedToDriftKey, true);
    await prefs.setInt(bestValueKey, await database.getBestReadingValue());
    return;
  }

  final dateList = prefs.getStringList("dates") ?? const <String>[];
  if (dateList.isEmpty) {
    await prefs.setBool(readingsMigratedToDriftKey, true);
    await prefs.setInt(bestValueKey, 0);
    return;
  }

  final sortedDates = {...dateList}.toList()..sort();
  final entries = <DayEntry>[];
  for (final dateKey in sortedDates) {
    final data = prefs.getString(dateKey);
    if (data == null || data.isEmpty) {
      continue;
    }

    entries.add(DayEntry.fromJson(json.decode(data) as Map<String, dynamic>));
  }

  await database.replaceAllDayEntries(entries);
  await prefs.setBool(readingsMigratedToDriftKey, true);
  await prefs.setInt(bestValueKey, await database.getBestReadingValue());
}

Future<void> _storeBestValueAfterWrite(
  AppDatabase database, {
  int? fallbackCandidate,
}) async {
  final bestValue = await database.getBestReadingValue();
  await setBestValue(bestValue > 0 ? bestValue : (fallbackCandidate ?? 0));
}

Future<void> debugLoadMockData({int count = defaultMockEntryCount}) async {
  final database = await _getDatabase();
  final entries = buildMockDayEntries(count: count);
  await database.replaceAllDayEntries(entries);
  await setBestValue(await database.getBestReadingValue());
}

Future<void> debugClearAllData() async {
  final database = await _getDatabase();
  await database.replaceAllDayEntries(const []);
  await setBestValue(0);
}

@visibleForTesting
void debugUseDatabase(AppDatabase? database, {bool runMigration = false}) {
  _databaseFuture = database == null
      ? null
      : Future(() async {
          if (runMigration) {
            await _migrateReadingsToDriftIfNeeded(database);
          }
          return database;
        });
}
