import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peakflow/db/app_database.dart';
import 'package:peakflow/db/prefs.dart';
import 'package:peakflow/debug/mock_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
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

  test(
    'debugLoadMockData seeds the requested number of sample entries',
    () async {
      await debugLoadMockData(count: 75);

      final entries = await getDayEntries();

      expect(entries, hasLength(75));
      expect(entries.first.date.isBefore(entries.last.date), isTrue);
      expect(entries.any((entry) => entry.readings.length > 1), isTrue);
      expect(entries.any((entry) => entry.note.isNotEmpty), isTrue);
      expect(await getBestValue(), greaterThan(0));
    },
  );

  test(
    'debugLoadMockData clamps oversized requests to the configured maximum',
    () async {
      await debugLoadMockData(count: maxMockEntryCount + 250);

      final entries = await getDayEntries();

      expect(entries, hasLength(maxMockEntryCount));
    },
  );

  test(
    'debugClearAllData removes seeded entries and resets best value',
    () async {
      await debugLoadMockData();

      await debugClearAllData();

      expect(await getDayEntries(), isEmpty);
      expect(await database.countStoredDays(), 0);
      expect(await getBestValue(), 0);
    },
  );
}
