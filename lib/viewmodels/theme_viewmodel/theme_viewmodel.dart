import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { system, light, dark }

class ThemeViewModel extends ChangeNotifier {
  AppThemeMode _themeMode = AppThemeMode.system;
  static const String _themeKey = 'app_theme_mode';

  AppThemeMode get appThemeMode => _themeMode;

  ThemeMode get themeMode {
    switch (_themeMode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  // Legacy getter for backward compatibility
  bool get isDarkMode => _themeMode == AppThemeMode.dark;

  ThemeViewModel() {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey) ?? 0;
    _themeMode = AppThemeMode.values[themeIndex];
    notifyListeners();
  }

  Future<void> _saveThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, _themeMode.index);
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    if (_themeMode != mode) {
      _themeMode = mode;
      await _saveThemeMode();
      notifyListeners();
    }
  }

  // Legacy method for backward compatibility
  Future<void> toggleTheme() async {
    final newMode = _themeMode == AppThemeMode.dark
        ? AppThemeMode.light
        : AppThemeMode.dark;
    await setThemeMode(newMode);
  }

  // Legacy method for backward compatibility
  Future<void> setTheme(bool isDark) async {
    await setThemeMode(isDark ? AppThemeMode.dark : AppThemeMode.light);
  }
}
