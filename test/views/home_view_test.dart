import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peakflow/debug/mock_data.dart';
import 'package:peakflow/models/day_entry_model.dart';
import 'package:peakflow/providers/day_entries_provider.dart';
import 'package:peakflow/providers/day_entries_state.dart';
import 'package:peakflow/views/home_view.dart';

import '../test_helpers/widget_test_setup.dart';

void main() {
  setUpWidgetTestDatabase();

  testWidgets(
    'timeline scrollbar scrolls and reveals date anchors while dragging',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final entries = buildMockDayEntries(count: 180);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            entryListProvider.overrideWith(
              (ref) => _SeededDayEntriesState(entries),
            ),
          ],
          child: const MaterialApp(home: HomeView()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump();

      const handleKey = ValueKey('homeTimelineHandle');
      const monthLabelKey = ValueKey('homeTimelineMonthLabel');
      const yearMarkerKey = ValueKey('homeTimelineYearMarker-2026');

      expect(find.byKey(handleKey), findsOneWidget);

      final scrollableState = tester.state<ScrollableState>(
        find.byType(Scrollable),
      );
      final initialOffset = scrollableState.position.pixels;

      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(handleKey)),
      );
      await gesture.moveBy(const Offset(0, 260));
      await tester.pump(const Duration(milliseconds: 150));

      expect(_opacityFor(tester, monthLabelKey), 1);
      expect(_opacityFor(tester, yearMarkerKey), 1);
      expect(scrollableState.position.pixels, greaterThan(initialOffset));

      await gesture.up();
      await tester.pump(const Duration(milliseconds: 150));

      expect(_opacityFor(tester, monthLabelKey), 0);
    },
  );
}

double _opacityFor(WidgetTester tester, Key key) {
  final opacityFinder = find.ancestor(
    of: find.byKey(key),
    matching: find.byType(AnimatedOpacity),
  );
  return tester.widget<AnimatedOpacity>(opacityFinder.first).opacity;
}

class _SeededDayEntriesState extends DayEntriesState {
  _SeededDayEntriesState(List<DayEntry> entries) {
    state = entries;
  }

  @override
  Future<void> loadEntries() async {}
}
