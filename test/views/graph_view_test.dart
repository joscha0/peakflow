import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peakflow/models/day_entry_model.dart';
import 'package:peakflow/providers/day_entries_provider.dart';
import 'package:peakflow/providers/day_entries_state.dart';
import 'package:peakflow/views/graph_view.dart';

import '../test_helpers/test_data.dart';
import '../test_helpers/widget_test_setup.dart';

void main() {
  setUpWidgetTestDatabase();

  testWidgets('graph shows stats for the selected date range', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final entries = [
      buildDayEntry(
        date: DateTime(2026, 4, 24),
        readings: const [],
        morningValue: 411,
        eveningValue: 503,
      ),
      buildDayEntry(
        date: DateTime(2026, 4, 25),
        readings: const [],
        morningValue: 631,
      ),
      buildDayEntry(
        date: DateTime(2026, 4, 26),
        readings: const [],
        eveningValue: 337,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          entryListProvider.overrideWith((ref) => _SeededEntries(entries)),
        ],
        child: const MaterialApp(home: GraphView()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump();

    expect(find.text('Avg'), findsOneWidget);
    expect(find.text('471 L/min'), findsOneWidget);
    expect(find.text('Highest'), findsOneWidget);
    expect(find.text('631 L/min'), findsOneWidget);
    expect(find.text('Lowest'), findsOneWidget);
    expect(find.text('337 L/min'), findsOneWidget);
    expect(find.text('Measurements'), findsOneWidget);
    expect(find.text('4 times'), findsOneWidget);
    expect(find.text('Reports'), findsOneWidget);
    expect(find.text('PDF Report'), findsOneWidget);
    expect(find.text('CSV Report'), findsOneWidget);
  });

  testWidgets('date range controls stay fixed while graph content scrolls', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 520);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final entries = [
      buildDayEntry(
        date: DateTime(2026, 4, 24),
        readings: const [],
        morningValue: 411,
        eveningValue: 503,
      ),
      buildDayEntry(
        date: DateTime(2026, 4, 25),
        readings: const [],
        morningValue: 631,
      ),
      buildDayEntry(
        date: DateTime(2026, 4, 26),
        readings: const [],
        eveningValue: 337,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          entryListProvider.overrideWith((ref) => _SeededEntries(entries)),
        ],
        child: const MaterialApp(home: GraphView()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump();

    final dateRangeFinder = find.text('Date Range');
    final initialDateRangeTop = tester.getTopLeft(dateRangeFinder).dy;

    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, -260),
    );
    await tester.pumpAndSettle();

    expect(dateRangeFinder, findsOneWidget);
    expect(
      tester.getTopLeft(dateRangeFinder).dy,
      moreOrLessEquals(initialDateRangeTop),
    );
  });
}

class _SeededEntries extends DayEntriesState {
  _SeededEntries(List<DayEntry> entries) {
    state = entries;
  }

  @override
  Future<void> loadEntries() async {}
}
