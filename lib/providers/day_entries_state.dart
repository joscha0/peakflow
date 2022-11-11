import 'dart:convert';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:peakflow/models/day_entry_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DayEntriesState extends StateNotifier<List<DayEntry>> {
  DayEntriesState() : super([]);

  Future<void> getEntries() async {
    List<DayEntry> entries = [];
    final prefs = await SharedPreferences.getInstance();
    final List<String> dateList = prefs.getStringList("dates") ?? [];
    bool sortUp = prefs.getBool('sortValue') ?? true;
    dateList.sort();

    for (String date in dateList) {
      entries.add(DayEntry.fromJson(json.decode(prefs.getString(date) ?? "")));
    }
    if (sortUp) {
      state = entries;
    } else {
      state = entries.reversed.toList();
    }
  }

  void changeSort() {
    state = state.reversed.toList();
  }
}
