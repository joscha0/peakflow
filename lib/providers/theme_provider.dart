import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:peakflow/providers/theme_state.dart';

final initialIsDarkModeProvider = Provider<bool>(
  (ref) =>
      WidgetsBinding.instance.platformDispatcher.platformBrightness ==
      Brightness.dark,
);

final themeStateNotifier = ChangeNotifierProvider<ThemeState>(
  (ref) => ThemeState(initialIsDarkMode: ref.watch(initialIsDarkModeProvider)),
);
