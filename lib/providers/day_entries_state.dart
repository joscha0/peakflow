import 'package:flutter_riverpod/legacy.dart';
import 'package:peakflow/db/prefs.dart';
import 'package:peakflow/models/day_entry_model.dart';

class DayEntriesState extends StateNotifier<List<DayEntry>> {
  DayEntriesState() : super([]);

  Future<void> loadEntries() async {
    List<DayEntry> entries = await getEntries();
    bool sortUp = await getSortValue();
    if (sortUp) {
      state = entries;
    } else {
      state = entries.reversed.toList();
    }
  }

  Future<List<DayEntry>> getEntries() async {
    return getDayEntries();
  }

  void changeSort() {
    state = state.reversed.toList();
  }
}
