import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peakflow/global/consts.dart';
import 'package:peakflow/providers/theme_provider.dart';
import 'package:peakflow/views/home_view.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeStateNotifier);
    final activeTheme = themeState.isDarkMode ? darkTheme : lightTheme;

    return MaterialApp(
      home: const HomeView(),
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      themeAnimationDuration: Duration.zero,
      builder: (context, child) => ColoredBox(
        color: activeTheme.scaffoldBackgroundColor,
        child: child ?? const SizedBox.shrink(),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
