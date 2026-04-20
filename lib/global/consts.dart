import 'package:flutter/material.dart';

const Map<String, bool> defaultCheckboxValues = {
  "Cough": false,
  "Cough night": false,
  "Wheezing breathing": false,
  "Shortness of breath": false,
  "Difficult breathing": false,
  "Chest tightness or pain": false,
  "Unable to work": false,
};

Color lightBackground = const Color.fromRGBO(246, 246, 246, 1);
Color darkBackground = Colors.black;
Color darkCard = Colors.grey.shade900;
Color accent = Colors.blueAccent.shade700;

ThemeData lightTheme = ThemeData(
  useMaterial3: false,
  scaffoldBackgroundColor: lightBackground,
  appBarTheme: AppBarTheme(backgroundColor: lightBackground, elevation: 0),
  colorScheme: ColorScheme.fromSeed(
    seedColor: accent,
    brightness: Brightness.light,
    surface: Colors.white,
  ),
  cardTheme: const CardThemeData(shadowColor: Colors.black26),
  sliderTheme: const SliderThemeData(valueIndicatorColor: Colors.white),
  checkboxTheme: CheckboxThemeData(fillColor: WidgetStatePropertyAll(accent)),
);

ThemeData darkTheme = ThemeData(
  useMaterial3: false,
  scaffoldBackgroundColor: darkBackground,
  appBarTheme: AppBarTheme(backgroundColor: darkBackground, elevation: 0),
  colorScheme: ColorScheme.fromSeed(
    seedColor: accent,
    brightness: Brightness.dark,
    surface: darkCard,
  ),
  sliderTheme: SliderThemeData(valueIndicatorColor: darkCard),
  checkboxTheme: CheckboxThemeData(
    fillColor: WidgetStatePropertyAll(Colors.blueAccent.shade700),
  ),
  cardColor: darkCard,
);
