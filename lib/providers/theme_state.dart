import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeState extends ChangeNotifier {
  bool isDarkMode = ThemeMode.system == ThemeMode.dark;

  ThemeState() {
    SharedPreferences.getInstance().then((prefs) {
      isDarkMode =
          prefs.getBool("isDarkMode") ?? ThemeMode.system == ThemeMode.dark;
      notifyListeners();
    });
  }

  void setIsDarkMode(bool value) {
    isDarkMode = value;
    notifyListeners();
  }
}
