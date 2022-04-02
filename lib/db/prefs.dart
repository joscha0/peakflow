import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:peakflow/models/day_entry_model.dart';
import 'package:peakflow/models/reading_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<int> getBestValue() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt("bestValue") ?? 0;
}

void setBestValue(int value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt("bestValue", value);
}

void updateBestValue() async {
  final prefs = await SharedPreferences.getInstance();
  int newBest = 0;
  List<String> dateList = prefs.getStringList("dates") ?? [];
  for (String date in dateList) {
    String? data = prefs.getString(date);
    if (data != null) {
      DayEntry entry = DayEntry.fromJson(json.decode(data));
      for (Reading reading in entry.readings) {
        if (reading.value > newBest) {
          newBest = reading.value;
        }
      }
    }
  }
}

Future<void> addReading(
    DateTime date,
    TimeOfDay time,
    int value,
    String noteReading,
    String noteDay,
    Map<String, bool> checkboxValues) async {
  DayEntry entry;
  String key = DateFormat("yyyyMMdd").format(date);
  final prefs = await SharedPreferences.getInstance();
  String? oldEntry = prefs.getString(key);
  if (oldEntry != null) {
    entry = DayEntry.fromJson(json.decode(oldEntry));
  } else {
    entry = DayEntry(
      date: date,
      readings: [],
      note: noteDay,
      morningValue: 0,
      eveningValue: 0,
      checkboxValues: checkboxValues,
    );
  }
  entry.readings.add(Reading(
    time: time,
    value: value,
    note: noteReading,
  ));
  int bestValue = await getBestValue();
  if (value > bestValue) {
    setBestValue(value);
  }
  List<int> morningEvening = getMorningEveningValue(entry.readings);
  DayEntry newEntry = DayEntry(
    date: entry.date,
    readings: entry.readings,
    note: noteDay,
    morningValue: morningEvening[0],
    eveningValue: morningEvening[1],
    checkboxValues: checkboxValues,
  );

  await prefs.setString(key, json.encode(newEntry.toJson()));
  final List<String> dateList = prefs.getStringList("dates") ?? [];
  if (!dateList.contains(key)) {
    dateList.add(key);
    await prefs.setStringList("dates", dateList);
  }
}

Future<void> deleteReading(DateTime date, int readingIndex) async {
  final prefs = await SharedPreferences.getInstance();
  String key = DateFormat("yyyyMMdd").format(date);
  String? oldEntry = prefs.getString(key);
  if (oldEntry != null) {
    DayEntry entry = DayEntry.fromJson(json.decode(oldEntry));
    entry.readings.removeAt(readingIndex);
    print(entry.readings);
    List<int> morningEvening = getMorningEveningValue(entry.readings);
    DayEntry newEntry = DayEntry(
      date: entry.date,
      readings: entry.readings,
      note: entry.note,
      morningValue: morningEvening[0],
      eveningValue: morningEvening[1],
      checkboxValues: entry.checkboxValues,
    );
    print(entry.readings.length);
    print(newEntry.readings.length);
    await prefs.setString(key, json.encode(newEntry.toJson()));
    updateBestValue();
  }
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
  morningEvening
      .add(morningCount >= 1 ? (morningSum / morningCount).round() : -1);
  morningEvening
      .add(eveningCount >= 1 ? (eveningSum / eveningCount).round() : -1);
  return morningEvening;
}

Future<void> deleteDay(DateTime date) async {
  final prefs = await SharedPreferences.getInstance();
  String key = DateFormat("yyyyMMdd").format(date);
  await prefs.remove(key);
  List<String> dateList = prefs.getStringList("dates") ?? [];
  dateList.remove(key);
  await prefs.setStringList("dates", dateList);
  updateBestValue();
}
