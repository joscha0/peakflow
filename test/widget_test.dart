import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peakflow/app.dart';
import 'package:peakflow/db/app_database.dart';
import 'package:peakflow/db/prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    debugUseDatabase(AppDatabase(NativeDatabase.memory()));
  });

  tearDown(() {
    debugUseDatabase(null);
  });

  testWidgets('app renders home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: App()));

    await tester.pumpAndSettle();

    expect(find.text('PEAK FLOW'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}
