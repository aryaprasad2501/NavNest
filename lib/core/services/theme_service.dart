import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum NavThemePreference {
  solar,    // Auto Dawn (6am-7pm) & Midnight (7pm-6am)
  system,   // Follow device OS brightness
  dawn,     // Force Dawn (Morning Nature light)
  midnight, // Force Midnight (Moonlit Nature dark)
}

class ThemeService extends ChangeNotifier {
  static const String _keyThemeMode = 'navnest_theme_mode';
  static const String _keyThemeModeStr = 'navnest_theme_mode_str';
  static const String _keyThemePref = 'navnest_theme_pref';

  ThemeMode _themeMode = ThemeMode.system;
  NavThemePreference _preference = NavThemePreference.system;

  ThemeMode get themeMode => _themeMode;
  NavThemePreference get preference => _preference;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final prefStr = prefs.getString(_keyThemePref);

    if (prefStr != null) {
      switch (prefStr) {
        case 'solar':
          _preference = NavThemePreference.solar;
          _themeMode = _calculateSolarMode();
          break;
        case 'dawn':
          _preference = NavThemePreference.dawn;
          _themeMode = ThemeMode.light;
          break;
        case 'midnight':
          _preference = NavThemePreference.midnight;
          _themeMode = ThemeMode.dark;
          break;
        default:
          _preference = NavThemePreference.system;
          _themeMode = ThemeMode.system;
          break;
      }
    } else {
      final modeStr = prefs.getString(_keyThemeModeStr);
      if (modeStr != null) {
        if (modeStr == 'dark') {
          _preference = NavThemePreference.midnight;
          _themeMode = ThemeMode.dark;
        } else if (modeStr == 'light') {
          _preference = NavThemePreference.dawn;
          _themeMode = ThemeMode.light;
        } else {
          _preference = NavThemePreference.system;
          _themeMode = ThemeMode.system;
        }
      } else {
        final isDark = prefs.getBool(_keyThemeMode);
        if (isDark != null) {
          _preference = isDark ? NavThemePreference.midnight : NavThemePreference.dawn;
          _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
        } else {
          _preference = NavThemePreference.system;
          _themeMode = ThemeMode.system;
        }
      }
    }
    notifyListeners();
  }

  ThemeMode _calculateSolarMode() {
    final hour = DateTime.now().hour;
    // 06:00 to 18:30 is Dawn (Light); 18:30 to 06:00 is Midnight (Dark)
    return (hour >= 6 && hour < 19) ? ThemeMode.light : ThemeMode.dark;
  }

  Future<void> setPreference(NavThemePreference pref) async {
    _preference = pref;
    switch (pref) {
      case NavThemePreference.solar:
        _themeMode = _calculateSolarMode();
        break;
      case NavThemePreference.dawn:
        _themeMode = ThemeMode.light;
        break;
      case NavThemePreference.midnight:
        _themeMode = ThemeMode.dark;
        break;
      case NavThemePreference.system:
        _themeMode = ThemeMode.system;
        break;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyThemePref, pref.name);
    await prefs.setString(_keyThemeModeStr, _themeMode == ThemeMode.dark ? 'dark' : (_themeMode == ThemeMode.light ? 'light' : 'system'));
    await prefs.setBool(_keyThemeMode, _themeMode == ThemeMode.dark);
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.dark) {
      await setPreference(NavThemePreference.dawn);
    } else {
      await setPreference(NavThemePreference.midnight);
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == ThemeMode.dark) {
      await setPreference(NavThemePreference.midnight);
    } else if (mode == ThemeMode.light) {
      await setPreference(NavThemePreference.dawn);
    } else {
      await setPreference(NavThemePreference.system);
    }
  }
}
