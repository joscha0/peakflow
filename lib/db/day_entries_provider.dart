import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:peakflow/db/day_entries_state.dart';
import 'package:peakflow/models/day_entry_model.dart';

final entryListProvider =
    StateNotifierProvider<DayEntriesState, List<DayEntry>>(
        (ref) => DayEntriesState());
