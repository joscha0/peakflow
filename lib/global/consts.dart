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

const Color lightBackground = Color.fromRGBO(246, 246, 246, 1);
const Color darkBackground = Colors.black;
final Color darkCard = Colors.grey.shade900;
final Color accent = Colors.blueAccent.shade700;

final ColorScheme lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: accent,
  onPrimary: Colors.black,
  secondary: accent,
  onSecondary: Colors.white,
  error: Colors.red,
  onError: Colors.red,
  surface: Colors.white,
  onSurface: Colors.black,
);

final ColorScheme darkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: accent,
  onPrimary: Colors.white,
  secondary: accent,
  onSecondary: Colors.white,
  error: Colors.red,
  onError: Colors.red,
  surface: darkCard,
  onSurface: Colors.white,
);

ThemeData lightTheme = ThemeData(
  useMaterial3: false,
  primaryColor: accent,
  scaffoldBackgroundColor: lightBackground,
  colorScheme: lightColorScheme,
  appBarTheme: const AppBarTheme(
    backgroundColor: lightBackground,
    foregroundColor: Colors.black,
    elevation: 0,
    iconTheme: IconThemeData(color: Colors.black),
  ),
  cardTheme: const CardThemeData(shadowColor: Colors.black26),
  sliderTheme: const SliderThemeData(valueIndicatorColor: Colors.white),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: accent,
    foregroundColor: Colors.white,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: accent,
      foregroundColor: Colors.white,
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(foregroundColor: accent),
  ),
  iconTheme: const IconThemeData(color: Colors.black),
);

ThemeData darkTheme = ThemeData(
  useMaterial3: false,
  primaryColor: accent,
  scaffoldBackgroundColor: darkBackground,
  colorScheme: darkColorScheme,
  appBarTheme: const AppBarTheme(
    backgroundColor: darkBackground,
    foregroundColor: Colors.white,
    elevation: 0,
    iconTheme: IconThemeData(color: Colors.white),
  ),
  sliderTheme: SliderThemeData(valueIndicatorColor: darkCard),
  cardColor: darkCard,
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: accent,
    foregroundColor: Colors.white,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: accent,
      foregroundColor: Colors.white,
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(foregroundColor: accent),
  ),
  iconTheme: const IconThemeData(color: Colors.white),
);
