import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeState extends ChangeNotifier {
  bool isDarkMode =
      SchedulerBinding.instance!.window.platformBrightness == Brightness.dark;

  ThemeState() {
    SharedPreferences.getInstance().then((prefs) {
      isDarkMode = prefs.getBool("isDarkMode") ??
          SchedulerBinding.instance!.window.platformBrightness ==
              Brightness.dark;
      notifyListeners();
    });
  }

  void setIsDarkMode(bool value) {
    isDarkMode = value;
    notifyListeners();
  }
}
