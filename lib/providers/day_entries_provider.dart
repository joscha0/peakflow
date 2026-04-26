import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:peakflow/models/day_entry_model.dart';
import 'package:peakflow/providers/day_entries_state.dart';

final entryListProvider =
    StateNotifierProvider<DayEntriesState, List<DayEntry>>(
      (ref) => DayEntriesState(),
    );

final timelineEntryListProvider = Provider<List<DayEntry>>((ref) {
  final entries = ref.watch(entryListProvider);
  return [...entries]
    ..sort((first, second) => second.date.compareTo(first.date));
});
