import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peakflow/global/consts.dart';
import 'package:peakflow/providers/theme_provider.dart';
import 'package:peakflow/views/home_view.dart';

class PeakFlowScrollBehavior extends MaterialScrollBehavior {
  const PeakFlowScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeStateNotifier);
    final lightTheme = buildLightTheme(themeState.primaryColor);
    final darkTheme = buildDarkTheme(themeState.primaryColor);
    final activeTheme = themeState.isDarkMode ? darkTheme : lightTheme;

    return MaterialApp(
      home: const HomeView(),
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      scrollBehavior: const PeakFlowScrollBehavior(),
      themeAnimationDuration: Duration.zero,
      builder: (context, child) => ColoredBox(
        color: activeTheme.scaffoldBackgroundColor,
        child: child ?? const SizedBox.shrink(),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
