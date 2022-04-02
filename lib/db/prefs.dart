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

Future<void> addReading(
    DateTime date, TimeOfDay time, int value, String noteDay) async {
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
    );
  }
  entry.readings.add(Reading(time: time, value: value));
  int bestValue = await getBestValue();
  if (value > bestValue) {
    setBestValue(value);
  }
  int morningSum = 0;
  int morningCount = 0;
  int eveningSum = 0;
  int eveningCount = 0;
  for (Reading reading in entry.readings) {
    if (reading.time.hour < 12) {
      morningSum += reading.value;
      morningCount++;
    } else {
      eveningSum += reading.value;
      eveningCount++;
    }
  }
  DayEntry newEntry = DayEntry(
    date: entry.date,
    readings: entry.readings,
    note: entry.note,
    morningValue: morningCount >= 1 ? (morningSum / morningCount).round() : -1,
    eveningValue: eveningCount >= 1 ? (eveningSum / eveningCount).round() : -1,
  );

  print(newEntry.toJson().toString());

  await prefs.setString(key, json.encode(newEntry.toJson()));
  final List<String> dateList = prefs.getStringList("dates") ?? [];
  if (!dateList.contains(key)) {
    dateList.add(key);
    await prefs.setStringList("dates", dateList);
  }
}