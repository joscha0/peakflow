import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeState extends ChangeNotifier {
  bool isDarkMode =
      WidgetsBinding.instance.platformDispatcher.platformBrightness ==
      Brightness.dark;

  ThemeState() {
    SharedPreferences.getInstance().then((prefs) {
      isDarkMode =
          prefs.getBool("isDarkMode") ??
          WidgetsBinding.instance.platformDispatcher.platformBrightness ==
              Brightness.dark;
      notifyListeners();
    });
  }

  void setIsDarkMode(bool value) {
    isDarkMode = value;
    notifyListeners();
  }
}
