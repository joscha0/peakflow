import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peakflow/views/day_view.dart';

import '../test_helpers/test_data.dart';
import '../test_helpers/widget_test_setup.dart';

void main() {
  setUpWidgetTestDatabase();

  testWidgets('day view renders notes, symptoms, and readings', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: DayView(
            dayEntry: buildDayEntry(
              date: DateTime(2026, 4, 21),
              note: 'Existing day note',
              readings: [
                buildReading(hour: 7, minute: 30, value: 280, note: 'Steady'),
              ],
              checkboxValues: const {'Cough': true},
              morningValue: 280,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Notes'), findsOneWidget);
    expect(find.text('Existing day note'), findsOneWidget);
    expect(find.text('Symptoms'), findsOneWidget);
    expect(find.text('Cough'), findsOneWidget);
    expect(find.text('Readings'), findsOneWidget);
    expect(find.text('Steady'), findsOneWidget);
    expect(find.text('280'), findsOneWidget);
  });

  testWidgets('day view can delete a reading from a fixed-length list', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: DayView(
            dayEntry: buildDayEntry(
              date: DateTime(2026, 4, 21),
              readings: List.unmodifiable([
                buildReading(hour: 7, minute: 30, value: 280, note: 'Steady'),
              ]),
              morningValue: 280,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final popupButtons = find.byWidgetPredicate(
      (widget) => widget is PopupMenuButton,
    );

    await tester.tap(popupButtons.last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('delete').last);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
