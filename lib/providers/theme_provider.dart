import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  final SharedPreferences _prefs;
  ThemeMode _themeMode = ThemeMode.dark; // Varsayılan koyu tema
  
  ThemeProvider(this._prefs) {
    _loadTheme();
  }
  
  ThemeMode get themeMode => _themeMode;
  
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  
  void _loadTheme() {
    final isDark = _prefs.getBool('isDarkMode') ?? true; // Varsayılan koyu
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
  
  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    _prefs.setBool('isDarkMode', _themeMode == ThemeMode.dark);
    notifyListeners();
  }
  
  void setTheme(ThemeMode mode) {
    _themeMode = mode;
    _prefs.setBool('isDarkMode', mode == ThemeMode.dark);
    notifyListeners();
  }
}