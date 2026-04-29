import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peakflow/widgets/platform_date_time_picker.dart';

void main() {
  testWidgets('date picker uses Cupertino controls on iOS', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () {
                showPlatformDatePicker(
                  context: context,
                  initialDate: DateTime(2026, 4, 21),
                  firstDate: DateTime(2000, 1, 1),
                  lastDate: DateTime(2026, 4, 29),
                );
              },
              child: const Text('Pick date'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Pick date'));
    await tester.pumpAndSettle();

    expect(find.byType(CupertinoDatePicker), findsOneWidget);
  });

  testWidgets('time picker uses Cupertino controls on iOS', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () {
                showPlatformTimePicker(
                  context: context,
                  initialTime: const TimeOfDay(hour: 8, minute: 30),
                );
              },
              child: const Text('Pick time'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Pick time'));
    await tester.pumpAndSettle();

    expect(find.byType(CupertinoDatePicker), findsOneWidget);
  });
}
