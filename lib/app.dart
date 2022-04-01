import 'package:flutter/material.dart';
import 'package:peakflow/views/home_view.dart';

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const HomeView(),
      darkTheme: ThemeData(
        colorScheme: ColorScheme(
          brightness: Brightness.dark,
          primary: Colors.black,
          onPrimary: Colors.white,
          secondary: Colors.blueAccent,
          onSecondary: Colors.white,
          error: Colors.red,
          onError: Colors.red,
          background: Colors.black,
          onBackground: Colors.white,
          surface: Colors.grey.shade900,
          onSurface: Colors.white,
        ),
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.dark,
      debugShowCheckedModeBanner: false,
    );
  }
}
