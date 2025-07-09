// lib/providers/theme_provider.dart - İYİLEŞTİRİLMİŞ VERSİYON
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  final SharedPreferences _prefs;
  ThemeMode _themeMode = ThemeMode.system; // SİSTEM AYARINI TAKİP ET (VARSAYILAN)
  
  ThemeProvider(this._prefs) {
    _loadTheme();
  }
  
  ThemeMode get themeMode => _themeMode;
  
  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      // Sistem ayarını kontrol et
      return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }
  
  void _loadTheme() {
    final themeString = _prefs.getString('theme_mode') ?? 'system';
    
    switch (themeString) {
      case 'light':
        _themeMode = ThemeMode.light;
        break;
      case 'dark':
        _themeMode = ThemeMode.dark;
        break;
      case 'system':
      default:
        _themeMode = ThemeMode.system;
        break;
    }
    
    notifyListeners();
  }
  
  void toggleTheme() {
    // Döngü: system → light → dark → system
    switch (_themeMode) {
      case ThemeMode.system:
        _themeMode = ThemeMode.light;
        break;
      case ThemeMode.light:
        _themeMode = ThemeMode.dark;
        break;
      case ThemeMode.dark:
        _themeMode = ThemeMode.system;
        break;
    }
    
    _saveTheme();
    notifyListeners();
  }
  
  void setTheme(ThemeMode mode) {
    _themeMode = mode;
    _saveTheme();
    notifyListeners();
  }
  
  void _saveTheme() {
    String themeString;
    switch (_themeMode) {
      case ThemeMode.light:
        themeString = 'light';
        break;
      case ThemeMode.dark:
        themeString = 'dark';
        break;
      case ThemeMode.system:
        themeString = 'system';
        break;
    }
    
    _prefs.setString('theme_mode', themeString);
  }
  
  // Tema durumu için getter'lar
  String get currentThemeText {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'Açık Tema';
      case ThemeMode.dark:
        return 'Koyu Tema';
      case ThemeMode.system:
        return 'Sistem Ayarı';
    }
  }
  
  IconData get currentThemeIcon {
    switch (_themeMode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.settings_brightness;
    }
  }
}