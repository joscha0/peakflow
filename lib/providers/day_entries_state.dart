import 'dart:convert';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:peakflow/models/day_entry_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DayEntriesState extends StateNotifier<List<DayEntry>> {
  DayEntriesState() : super([]);

  Future<void> loadEntries() async {
    List<DayEntry> entries = await getEntries();
    final prefs = await SharedPreferences.getInstance();
    bool sortUp = prefs.getBool('sortValue') ?? true;
    if (sortUp) {
      state = entries;
    } else {
      state = entries.reversed.toList();
    }
  }

  Future<List<DayEntry>> getEntries() async {
    List<DayEntry> entries = [];
    final prefs = await SharedPreferences.getInstance();
    final List<String> dateList = prefs.getStringList("dates") ?? [];
    dateList.sort();
    for (String date in dateList) {
      entries.add(DayEntry.fromJson(json.decode(prefs.getString(date) ?? "")));
    }
    return entries;
  }

  void changeSort() {
    state = state.reversed.toList();
  }
}
