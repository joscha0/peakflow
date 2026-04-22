import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peakflow/db/prefs.dart';
import 'package:peakflow/views/day_view.dart';
import 'package:peakflow/widgets/date_widget.dart';

import '../test_helpers/test_data.dart';
import '../test_helpers/widget_test_setup.dart';

void main() {
  setUpWidgetTestDatabase();

  testWidgets('date widget opens the day view when tapped', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final entry = buildDayEntry(
      date: DateTime(2026, 4, 19),
      note: 'Opened from tile',
      readings: [
        buildReading(hour: 8, minute: 0, value: 220, note: 'Morning reading'),
      ],
      checkboxValues: const {'Cough': true},
      morningValue: 220,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 120,
              height: 160,
              child: DateWidget(
                dayEntry: entry,
                referenceMaxValue: defaultMaxVolume,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DateWidget));
    await tester.pumpAndSettle();

    expect(find.byType(DayView), findsOneWidget);
    expect(find.text('Opened from tile'), findsOneWidget);
    expect(find.text('Morning reading'), findsOneWidget);
    expect(find.text('Cough'), findsOneWidget);
  });
}
