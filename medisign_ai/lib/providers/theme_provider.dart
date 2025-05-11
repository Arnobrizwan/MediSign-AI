import 'package:flutter/material.dart';
class ThemeProvider extends ChangeNotifier {
  ThemeData _themeData = _lightTheme;
  
  static final _lightTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.orange,
    primaryColor: const Color(0xFFF45B69),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF45B69),
      foregroundColor: Colors.white,
    ),
    scaffoldBackgroundColor: Colors.grey.shade50,
  );

  static final _darkTheme = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.orange,
    primaryColor: const Color(0xFFF45B69),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF45B69),
      foregroundColor: Colors.white,
    ),
    scaffoldBackgroundColor: Colors.grey.shade900,
    cardColor: Colors.grey.shade800,
  );

  static final _highContrastTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.orange,
    primaryColor: const Color(0xFFF45B69),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
    ),
    colorScheme: const ColorScheme.light(
      primary: Colors.black,
      secondary: Colors.white,
      background: Colors.white,
      surface: Colors.white,
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onBackground: Colors.black,
      onSurface: Colors.black,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      bodyMedium: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      titleLarge: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      titleMedium: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      titleSmall: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
    ),
    scaffoldBackgroundColor: Colors.white,
    cardColor: Colors.white,
    buttonTheme: const ButtonThemeData(
      textTheme: ButtonTextTheme.primary,
    ),
  );

  ThemeData get themeData => _themeData;

  void setTheme(String theme) {
    switch (theme) {
      case 'dark':
        _themeData = _darkTheme;
        break;
      case 'high_contrast':
        _themeData = _highContrastTheme;
        break;
      default:
        _themeData = _lightTheme;
    }
    notifyListeners();
  }
}