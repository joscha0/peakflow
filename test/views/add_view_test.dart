import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peakflow/views/add_view.dart';
import 'package:peakflow/widgets/peak_flow_value_selector.dart';

import '../test_helpers/widget_test_setup.dart';

void main() {
  setUpWidgetTestDatabase();

  testWidgets(
    'dragging selector does not dismiss or scroll add reading sheet',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: _AddReadingLauncher())),
      );
      await tester.tap(find.text('open sheet'));
      await tester.pumpAndSettle();

      expect(find.byType(AddView), findsOneWidget);

      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pumpAndSettle();

      final scrollableStates = find
          .descendant(
            of: find.byKey(const ValueKey('addReadingScrollView')),
            matching: find.byType(Scrollable),
          )
          .evaluate()
          .whereType<StatefulElement>()
          .map((element) => element.state)
          .whereType<ScrollableState>()
          .where((state) => state.position.maxScrollExtent > 0)
          .toList();
      expect(scrollableStates, hasLength(1));
      final scrollableState = scrollableStates.single;
      final initialOffset = scrollableState.position.pixels;

      final meterFinder = find.byKey(const ValueKey('peakFlowValueMeter'));
      expect(meterFinder, findsOneWidget);

      final upwardGesture = await tester.startGesture(
        tester.getCenter(meterFinder),
      );
      await upwardGesture.moveBy(const Offset(0, -260));
      await tester.pump();
      expect(scrollableState.position.pixels, initialOffset);
      await upwardGesture.up();

      final downwardGesture = await tester.startGesture(
        tester.getCenter(meterFinder),
      );
      await downwardGesture.moveBy(const Offset(0, 420));
      await tester.pump();
      await downwardGesture.up();
      await tester.pumpAndSettle();

      expect(find.byType(AddView), findsOneWidget);
    },
  );

  testWidgets('submitting a manually typed custom value does not round it', (
    WidgetTester tester,
  ) async {
    double? selectedValue;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PeakFlowValueSelector(
            value: 0,
            maxVolume: 850,
            onChanged: (value) {
              selectedValue = value;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final valueField = find.byType(TextFormField);

    await tester.enterText(valueField, '123');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(selectedValue, 123);
    expect(find.text('123'), findsOneWidget);
  });

  testWidgets(
    'typing inside a form does not update the controller during build',
    (WidgetTester tester) async {
      double selectedValue = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Form(
                  child: PeakFlowValueSelector(
                    value: selectedValue,
                    maxVolume: 850,
                    onChanged: (value) {
                      setState(() {
                        selectedValue = value;
                      });
                    },
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), '1');
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(selectedValue, 1);
    },
  );
}

class _AddReadingLauncher extends StatelessWidget {
  const _AddReadingLauncher();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () {
            showAddReadingDrawer(context);
          },
          child: const Text('open sheet'),
        ),
      ),
    );
  }
}
