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

  testWidgets('day and reading notes wrap on narrow screens', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    const longDayNote =
        'Medication helped and readings recovered later in the day after '
        'resting, hydrating, and checking again before dinner.';
    const longReadingNote =
        'Slightly tight chest before medication, improved after the second '
        'measurement and a quiet walk.';

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: DayView(
            dayEntry: buildDayEntry(
              date: DateTime(2026, 4, 21),
              note: longDayNote,
              readings: [
                buildReading(
                  hour: 7,
                  minute: 30,
                  value: 280,
                  note: longReadingNote,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(longDayNote), findsOneWidget);
    expect(find.text(longReadingNote), findsOneWidget);
  });

  testWidgets('deletion confirmation dialog shows day copy and cancels', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: _DialogLauncher(
          title: 'Delete day?',
          message:
              'This will permanently delete the day and all readings saved for it.',
          confirmLabel: 'Delete day',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('open dialog'));
    await tester.pumpAndSettle();

    expect(find.text('Delete day?'), findsOneWidget);
    expect(
      find.text(
        'This will permanently delete the day and all readings saved for it.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('cancelled'), findsOneWidget);
  });

  testWidgets('deletion confirmation dialog shows reading copy and confirms', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: _DialogLauncher(
          title: 'Delete reading?',
          message: 'This will permanently delete this reading.',
          confirmLabel: 'Delete reading',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('open dialog'));
    await tester.pumpAndSettle();

    expect(find.text('Delete reading?'), findsOneWidget);
    expect(
      find.text('This will permanently delete this reading.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Delete reading'));
    await tester.pumpAndSettle();

    expect(find.text('confirmed'), findsOneWidget);
  });
}

class _DialogLauncher extends StatefulWidget {
  const _DialogLauncher({
    required this.title,
    required this.message,
    required this.confirmLabel,
  });

  final String title;
  final String message;
  final String confirmLabel;

  @override
  State<_DialogLauncher> createState() => _DialogLauncherState();
}

class _DialogLauncherState extends State<_DialogLauncher> {
  String result = 'idle';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TextButton(
            onPressed: () async {
              final confirmed = await showDeletionConfirmationDialog(
                context: context,
                title: widget.title,
                message: widget.message,
                confirmLabel: widget.confirmLabel,
              );
              if (!mounted) {
                return;
              }
              setState(() {
                result = confirmed ? 'confirmed' : 'cancelled';
              });
            },
            child: const Text('open dialog'),
          ),
          Text(result),
        ],
      ),
    );
  }
}
