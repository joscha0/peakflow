import 'package:flutter_riverpod/legacy.dart';
import 'package:peakflow/db/prefs.dart';
import 'package:peakflow/models/day_entry_model.dart';

class DayEntriesState extends StateNotifier<List<DayEntry>> {
  DayEntriesState() : super([]);

  Future<List<DayEntry>>? _loadEntriesFuture;
  bool _hasLoadedEntries = false;

  Future<void> loadEntries() async {
    final pendingLoad = _loadEntriesFuture;
    if (pendingLoad != null) {
      await pendingLoad;
      return;
    }

    final loadFuture = _loadEntries();
    _loadEntriesFuture = loadFuture;

    try {
      state = await loadFuture;
      _hasLoadedEntries = true;
    } finally {
      if (identical(_loadEntriesFuture, loadFuture)) {
        _loadEntriesFuture = null;
      }
    }
  }

  Future<List<DayEntry>> getEntries({bool preferCached = true}) async {
    if (preferCached && _hasLoadedEntries) {
      return state;
    }

    final pendingLoad = _loadEntriesFuture;
    if (pendingLoad != null) {
      await pendingLoad;
      return state;
    }

    if (preferCached) {
      await loadEntries();
      return state;
    }

    return _loadEntries();
  }

  Future<List<DayEntry>> _loadEntries() async {
    return getDayEntries();
  }

  void removeDay(DateTime date) {
    state = state
        .where(
          (entry) =>
              entry.date.year != date.year ||
              entry.date.month != date.month ||
              entry.date.day != date.day,
        )
        .toList();
  }
}
