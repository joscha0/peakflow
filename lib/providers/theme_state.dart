import 'package:flutter/material.dart';
import 'package:peakflow/global/consts.dart';

class ThemeState extends ChangeNotifier {
  ThemeState({
    required bool initialIsDarkMode,
    required int initialPrimaryColorValue,
  }) : isDarkMode = initialIsDarkMode,
       primaryColor = _resolvePrimaryColor(initialPrimaryColorValue);

  bool isDarkMode;
  Color primaryColor;

  void setIsDarkMode(bool value) {
    isDarkMode = value;
    notifyListeners();
  }

  void setPrimaryColor(Color value) {
    primaryColor = _resolvePrimaryColor(value.toARGB32());
    notifyListeners();
  }

  static Color _resolvePrimaryColor(int colorValue) {
    for (final color in primaryColorOptions) {
      if (color.toARGB32() == colorValue) {
        return color;
      }
    }
    return defaultAccent;
  }
}
