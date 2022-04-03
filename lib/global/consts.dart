import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const Map<String, bool> defaultCheckboxValues = {
  "Cough": false,
  "Cough night": false,
  "Wheezing breathing": false,
  "Shortness of breath": false,
  "Difficult breathing": false,
  "Chest tightness or pain": false,
  "Unable to work": false
};

Color lightBackground = const Color.fromRGBO(246, 246, 246, 1);
Color darkBackground = Colors.black;
Color darkCard = Colors.grey.shade900;
Color accent = Colors.blueAccent.shade700;

ThemeData lightTheme = ThemeData(
  scaffoldBackgroundColor: lightBackground,
  appBarTheme: AppBarTheme(
    backgroundColor: lightBackground,
    elevation: 0,
  ),
  colorScheme: ColorScheme(
    brightness: Brightness.light,
    primary: accent,
    onPrimary: Colors.black,
    secondary: accent,
    onSecondary: Colors.white,
    error: Colors.red,
    onError: Colors.red,
    background: lightBackground,
    onBackground: Colors.black,
    surface: Colors.white,
    onSurface: Colors.black,
  ),
  cardTheme: const CardTheme(shadowColor: Colors.black26),
  sliderTheme: const SliderThemeData(valueIndicatorColor: Colors.white),
  toggleableActiveColor: accent,
  brightness: Brightness.light,
);

ThemeData darkTheme = ThemeData(
  scaffoldBackgroundColor: darkBackground,
  appBarTheme: AppBarTheme(backgroundColor: darkBackground, elevation: 0),
  colorScheme: ColorScheme(
    brightness: Brightness.dark,
    primary: accent,
    onPrimary: Colors.white,
    secondary: accent,
    onSecondary: Colors.white,
    error: Colors.red,
    onError: Colors.red,
    background: darkBackground,
    onBackground: Colors.white,
    surface: darkCard,
    onSurface: Colors.white,
  ),
  sliderTheme: SliderThemeData(valueIndicatorColor: darkCard),
  // cardTheme: const CardTheme(shadowColor: Colors.white24),
  toggleableActiveColor: Colors.blueAccent.shade700,
  cardColor: darkCard,
  brightness: Brightness.dark,
);
