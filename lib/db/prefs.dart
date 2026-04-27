import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:peakflow/db/app_database.dart';
import 'package:peakflow/debug/mock_data.dart';
import 'package:peakflow/global/consts.dart';
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

class JsonBackupImportPreview {
  const JsonBackupImportPreview({
    required this.currentDays,
    required this.currentReadings,
    required this.backupDays,
    required this.backupReadings,
    required this.currentOnlyDays,
    required this.backupOnlyDays,
    required this.overlappingDays,
    required this.daysChangedByMerge,
    required this.newReadings,
    required this.duplicateReadings,
    required this.newSymptomValues,
    required this.newDayNotes,
    required this.dayNoteConflicts,
  });

  final int currentDays;
  final int currentReadings;
  final int backupDays;
  final int backupReadings;
  final int currentOnlyDays;
  final int backupOnlyDays;
  final int overlappingDays;
  final int daysChangedByMerge;
  final int newReadings;
  final int duplicateReadings;
  final int newSymptomValues;
  final int newDayNotes;
  final int dayNoteConflicts;

  int get daysAfterMerge => currentDays + backupOnlyDays;
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

Future<JsonBackupImportPreview> previewDayEntriesJsonImport(String data) async {
  final backupEntries = decodeDayEntriesJsonBackup(data);
  final currentEntries = await getDayEntries();
  return _previewJsonBackupImport(
    currentEntries: currentEntries,
    backupEntries: backupEntries,
  );
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

Future<JsonBackupImportPreview> mergeDayEntriesJson(String data) async {
  final backupEntries = decodeDayEntriesJsonBackup(data);
  final database = await _getDatabase();
  final currentEntries = await database.getAllDayEntries();
  final preview = _previewJsonBackupImport(
    currentEntries: currentEntries,
    backupEntries: backupEntries,
  );
  final mergedEntries = _mergeJsonBackupEntries(
    currentEntries: currentEntries,
    backupEntries: backupEntries,
  );

  await database.replaceAllDayEntries(mergedEntries);
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(readingsMigratedToDriftKey, true);
  await prefs.setInt(bestValueKey, await database.getBestReadingValue());
  return preview;
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

JsonBackupImportPreview _previewJsonBackupImport({
  required List<DayEntry> currentEntries,
  required List<DayEntry> backupEntries,
}) {
  final currentByKey = {
    for (final entry in currentEntries) dateKeyFor(entry.date): entry,
  };
  final backupByKey = {
    for (final entry in backupEntries) dateKeyFor(entry.date): entry,
  };

  var newReadings = 0;
  var duplicateReadings = 0;
  var newSymptomValues = 0;
  var newDayNotes = 0;
  var dayNoteConflicts = 0;
  var daysChangedByMerge = 0;

  for (final backupEntry in backupEntries) {
    final currentEntry = currentByKey[dateKeyFor(backupEntry.date)];
    if (currentEntry == null) {
      newReadings += backupEntry.readings.length;
      daysChangedByMerge++;
      continue;
    }

    var dayChanged = false;
    for (final backupReading in backupEntry.readings) {
      if (currentEntry.readings.any(
        (currentReading) => _isSameReading(currentReading, backupReading),
      )) {
        duplicateReadings++;
      } else {
        newReadings++;
        dayChanged = true;
      }
    }

    for (final symptom in backupEntry.checkboxValues.entries) {
      if (symptom.value && currentEntry.checkboxValues[symptom.key] != true) {
        newSymptomValues++;
        dayChanged = true;
      }
    }

    if (currentEntry.note.trim().isEmpty &&
        backupEntry.note.trim().isNotEmpty) {
      newDayNotes++;
      dayChanged = true;
    } else if (currentEntry.note.trim().isNotEmpty &&
        backupEntry.note.trim().isNotEmpty &&
        currentEntry.note != backupEntry.note) {
      dayNoteConflicts++;
    }

    if (dayChanged) {
      daysChangedByMerge++;
    }
  }

  return JsonBackupImportPreview(
    currentDays: currentEntries.length,
    currentReadings: _countReadings(currentEntries),
    backupDays: backupEntries.length,
    backupReadings: _countReadings(backupEntries),
    currentOnlyDays: currentByKey.keys
        .where((key) => !backupByKey.containsKey(key))
        .length,
    backupOnlyDays: backupByKey.keys
        .where((key) => !currentByKey.containsKey(key))
        .length,
    overlappingDays: backupByKey.keys
        .where((key) => currentByKey.containsKey(key))
        .length,
    daysChangedByMerge: daysChangedByMerge,
    newReadings: newReadings,
    duplicateReadings: duplicateReadings,
    newSymptomValues: newSymptomValues,
    newDayNotes: newDayNotes,
    dayNoteConflicts: dayNoteConflicts,
  );
}

List<DayEntry> _mergeJsonBackupEntries({
  required List<DayEntry> currentEntries,
  required List<DayEntry> backupEntries,
}) {
  final mergedByKey = {
    for (final entry in currentEntries) dateKeyFor(entry.date): entry,
  };

  for (final backupEntry in backupEntries) {
    final key = dateKeyFor(backupEntry.date);
    final currentEntry = mergedByKey[key];
    if (currentEntry == null) {
      mergedByKey[key] = _withRecomputedMorningEvening(backupEntry);
      continue;
    }

    final readings = List<Reading>.from(currentEntry.readings);
    for (final backupReading in backupEntry.readings) {
      if (!readings.any((reading) => _isSameReading(reading, backupReading))) {
        readings.add(backupReading);
      }
    }

    readings.sort((first, second) {
      final hourCompare = first.time.hour.compareTo(second.time.hour);
      if (hourCompare != 0) {
        return hourCompare;
      }
      return first.time.minute.compareTo(second.time.minute);
    });

    final checkboxValues = <String, bool>{
      ...defaultCheckboxValues,
      ...currentEntry.checkboxValues,
    };
    for (final symptom in backupEntry.checkboxValues.entries) {
      if (symptom.value) {
        checkboxValues[symptom.key] = true;
      }
    }

    final note = currentEntry.note.trim().isEmpty
        ? backupEntry.note
        : currentEntry.note;
    final morningEvening = getMorningEveningValue(readings);
    mergedByKey[key] = DayEntry(
      date: currentEntry.date,
      readings: readings,
      note: note,
      morningValue: morningEvening[0],
      eveningValue: morningEvening[1],
      checkboxValues: checkboxValues,
    );
  }

  return mergedByKey.values.toList()
    ..sort((first, second) => first.date.compareTo(second.date));
}

DayEntry _withRecomputedMorningEvening(DayEntry entry) {
  final morningEvening = getMorningEveningValue(entry.readings);
  return DayEntry(
    date: entry.date,
    readings: entry.readings,
    note: entry.note,
    morningValue: morningEvening[0],
    eveningValue: morningEvening[1],
    checkboxValues: entry.checkboxValues,
  );
}

bool _isSameReading(Reading first, Reading second) {
  return first.time.hour == second.time.hour &&
      first.time.minute == second.time.minute &&
      first.value == second.value &&
      first.note == second.note;
}

int _countReadings(List<DayEntry> entries) {
  return entries.fold<int>(0, (count, entry) => count + entry.readings.length);
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
