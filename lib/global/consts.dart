import 'package:flutter/material.dart';

class BackgroundPageTransitionsBuilder extends PageTransitionsBuilder {
  const BackgroundPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final wrappedChild = ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: child,
    );

    final offsetAnimation = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

    return SlideTransition(position: offsetAnimation, child: wrappedChild);
  }
}

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
  canvasColor: lightBackground,
  cardColor: Colors.white,
  dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: lightBackground,
  ),
  popupMenuTheme: const PopupMenuThemeData(color: Colors.white),
  pageTransitionsTheme: const PageTransitionsTheme(
    builders: {
      TargetPlatform.android: BackgroundPageTransitionsBuilder(),
      TargetPlatform.iOS: BackgroundPageTransitionsBuilder(),
      TargetPlatform.linux: BackgroundPageTransitionsBuilder(),
      TargetPlatform.macOS: BackgroundPageTransitionsBuilder(),
      TargetPlatform.windows: BackgroundPageTransitionsBuilder(),
    },
  ),
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
  canvasColor: darkBackground,
  dialogTheme: const DialogThemeData(backgroundColor: darkBackground),
  bottomSheetTheme: const BottomSheetThemeData(backgroundColor: darkBackground),
  popupMenuTheme: PopupMenuThemeData(color: darkCard),
  pageTransitionsTheme: const PageTransitionsTheme(
    builders: {
      TargetPlatform.android: BackgroundPageTransitionsBuilder(),
      TargetPlatform.iOS: BackgroundPageTransitionsBuilder(),
      TargetPlatform.linux: BackgroundPageTransitionsBuilder(),
      TargetPlatform.macOS: BackgroundPageTransitionsBuilder(),
      TargetPlatform.windows: BackgroundPageTransitionsBuilder(),
    },
  ),
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
