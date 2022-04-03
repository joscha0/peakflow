import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:peakflow/providers/theme_state.dart';

final themeStateNotifier = ChangeNotifierProvider((ref) => ThemeState());
