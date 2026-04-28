import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peakflow/app.dart';
import 'package:peakflow/global/consts.dart';
import 'package:peakflow/providers/locale_provider.dart';
import 'package:peakflow/providers/locale_state.dart';
import 'package:peakflow/providers/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final initialIsDarkMode =
      prefs.getBool("isDarkMode") ??
      WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark;
  final initialPrimaryColorValue =
      prefs.getInt(primaryColorPreferenceKey) ?? defaultAccent.toARGB32();
  final initialLocaleChoice = AppLocaleChoice.initial(
    storedPreference: prefs.getString(localePreferenceKey),
    deviceLocales: WidgetsBinding.instance.platformDispatcher.locales,
  );

  runApp(
    ProviderScope(
      overrides: [
        initialLocaleChoiceProvider.overrideWithValue(initialLocaleChoice),
        initialIsDarkModeProvider.overrideWithValue(initialIsDarkMode),
        initialPrimaryColorValueProvider.overrideWithValue(
          initialPrimaryColorValue,
        ),
      ],
      child: const App(),
    ),
  );
}
