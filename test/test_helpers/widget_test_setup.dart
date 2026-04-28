import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peakflow/db/app_database.dart';
import 'package:peakflow/db/prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void setUpWidgetTestDatabase() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    database = AppDatabase(NativeDatabase.memory());
    debugUseDatabase(database);
  });

  tearDown(() async {
    debugUseDatabase(null);
    await database.close();
  });
}
