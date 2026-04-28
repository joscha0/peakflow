import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:peakflow/providers/locale_state.dart';

const String localePreferenceKey = 'localeChoice';

final initialLocaleChoiceProvider = Provider<AppLocaleChoice>(
  (ref) => AppLocaleChoice.english,
);

final localeStateNotifier = ChangeNotifierProvider<LocaleState>(
  (ref) => LocaleState(initialChoice: ref.watch(initialLocaleChoiceProvider)),
);
