import 'package:flutter_riverpod/legacy.dart';
import 'package:peakflow/providers/theme_state.dart';

final themeStateNotifier = ChangeNotifierProvider<ThemeState>(
  (ref) => ThemeState(),
);
