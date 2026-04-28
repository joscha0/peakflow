import 'package:flutter/material.dart';

enum AppLocaleChoice {
  english,
  german;

  String get preferenceValue {
    switch (this) {
      case AppLocaleChoice.english:
        return 'en';
      case AppLocaleChoice.german:
        return 'de';
    }
  }

  Locale get locale {
    switch (this) {
      case AppLocaleChoice.english:
        return const Locale('en');
      case AppLocaleChoice.german:
        return const Locale('de');
    }
  }

  static AppLocaleChoice fromPreferenceValue(String? value) {
    switch (value) {
      case 'de':
        return AppLocaleChoice.german;
      case 'en':
      default:
        return AppLocaleChoice.english;
    }
  }

  static AppLocaleChoice fromDeviceLocales(List<Locale> locales) {
    for (final locale in locales) {
      switch (locale.languageCode.toLowerCase()) {
        case 'de':
          return AppLocaleChoice.german;
        case 'en':
          return AppLocaleChoice.english;
      }
    }
    return AppLocaleChoice.english;
  }

  static AppLocaleChoice initial({
    required String? storedPreference,
    required List<Locale> deviceLocales,
  }) {
    switch (storedPreference) {
      case 'en':
      case 'de':
        return AppLocaleChoice.fromPreferenceValue(storedPreference);
      default:
        return AppLocaleChoice.fromDeviceLocales(deviceLocales);
    }
  }
}

class LocaleState extends ChangeNotifier {
  LocaleState({required AppLocaleChoice initialChoice})
    : choice = initialChoice;

  AppLocaleChoice choice;

  Locale get locale => choice.locale;

  void setChoice(AppLocaleChoice value) {
    if (choice == value) {
      return;
    }
    choice = value;
    notifyListeners();
  }
}
