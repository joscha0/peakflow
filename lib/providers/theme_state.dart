import 'package:flutter/material.dart';

class ThemeState extends ChangeNotifier {
  ThemeState({required bool initialIsDarkMode})
    : isDarkMode = initialIsDarkMode;

  bool isDarkMode;

  void setIsDarkMode(bool value) {
    isDarkMode = value;
    notifyListeners();
  }
}
