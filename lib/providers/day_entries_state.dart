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

    final loadFuture = _loadAndSortEntries();
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

    return _loadAndSortEntries();
  }

  Future<List<DayEntry>> _loadAndSortEntries() async {
    final results = await Future.wait<Object>([
      getDayEntries(),
      getSortValue(),
    ]);
    final entries = results[0] as List<DayEntry>;
    final sortUp = results[1] as bool;
    if (sortUp) {
      return entries;
    }
    return entries.reversed.toList(growable: false);
  }

  void changeSort() {
    state = state.reversed.toList(growable: false);
    _hasLoadedEntries = true;
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
