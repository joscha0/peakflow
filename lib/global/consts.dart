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

const String primaryColorPreferenceKey = "primaryColorValue";
const Color lightBackground = Color.fromRGBO(246, 246, 246, 1);
const Color darkBackground = Colors.black;
const Color defaultAccent = Color(0xFF2962FF);
const List<Color> primaryColorOptions = [
  Color(0xFF2962FF),
  Color(0xFF00897B),
  Color(0xFFD81B60),
  Color(0xFFFF8F00),
  Color(0xFF6D4C41),
  Color(0xFF5E35B1),
];
final Color darkCard = Colors.grey.shade900;

Color _onAccent(Color color) {
  return color.computeLuminance() > 0.45 ? Colors.black : Colors.white;
}

ColorScheme buildLightColorScheme(Color accent) {
  final onAccent = _onAccent(accent);
  return ColorScheme(
    brightness: Brightness.light,
    primary: accent,
    onPrimary: onAccent,
    secondary: accent,
    onSecondary: onAccent,
    error: Colors.red,
    onError: Colors.red,
    surface: Colors.white,
    onSurface: Colors.black,
  );
}

ColorScheme buildDarkColorScheme(Color accent) {
  final onAccent = _onAccent(accent);
  return ColorScheme(
    brightness: Brightness.dark,
    primary: accent,
    onPrimary: onAccent,
    secondary: accent,
    onSecondary: onAccent,
    error: Colors.red,
    onError: Colors.red,
    surface: darkCard,
    onSurface: Colors.white,
  );
}

ThemeData buildLightTheme(Color accent) {
  final colorScheme = buildLightColorScheme(accent);
  return ThemeData(
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
    colorScheme: colorScheme,
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
      foregroundColor: colorScheme.onPrimary,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: colorScheme.onPrimary,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: accent),
    ),
    iconTheme: const IconThemeData(color: Colors.black),
  );
}

ThemeData buildDarkTheme(Color accent) {
  final colorScheme = buildDarkColorScheme(accent);
  return ThemeData(
    useMaterial3: false,
    primaryColor: accent,
    scaffoldBackgroundColor: darkBackground,
    canvasColor: darkBackground,
    dialogTheme: const DialogThemeData(backgroundColor: darkBackground),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: darkBackground,
    ),
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
    colorScheme: colorScheme,
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
      foregroundColor: colorScheme.onPrimary,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: colorScheme.onPrimary,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: accent),
    ),
    iconTheme: const IconThemeData(color: Colors.white),
  );
}
