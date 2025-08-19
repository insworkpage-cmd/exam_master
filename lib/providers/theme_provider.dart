import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  // متد فعلی
  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  // متد جدید برای چرخش تم
  void toggleTheme() {
    if (_themeMode == ThemeMode.light) {
      _themeMode = ThemeMode.dark;
    } else if (_themeMode == ThemeMode.dark) {
      _themeMode = ThemeMode.system;
    } else {
      _themeMode = ThemeMode.light;
    }
    notifyListeners();
  }

  // متد کمکی برای بررسی تم فعلی
  bool get isDarkMode {
    return _themeMode == ThemeMode.dark;
  }

  // متد کمکی برای بررسی تم روشن
  bool get isLightMode {
    return _themeMode == ThemeMode.light;
  }

  // متد کمکی برای بررسی تم سیستم
  bool get isSystemMode {
    return _themeMode == ThemeMode.system;
  }
}
