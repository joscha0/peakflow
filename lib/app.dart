import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:peakflow/global/consts.dart';
import 'package:peakflow/providers/theme_provider.dart';
import 'package:peakflow/views/home_view.dart';

class App extends HookConsumerWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeStateNotifier);

    return MaterialApp(
      home: const HomeView(),
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      debugShowCheckedModeBanner: false,
    );
  }
}
