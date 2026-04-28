import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peakflow/app.dart';

import 'test_helpers/widget_test_setup.dart';

void main() {
  setUpWidgetTestDatabase();

  testWidgets('app renders home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: App()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}
