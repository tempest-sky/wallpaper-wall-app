import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppSettingsState extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  String get themeLabel {
    switch (_themeMode) {
      case ThemeMode.light:
        return '亮色主题';
      case ThemeMode.dark:
        return '暗色主题';
      case ThemeMode.system:
        return '跟随系统';
    }
  }

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  IconData get themeIcon {
    switch (_themeMode) {
      case ThemeMode.light:
        return Icons.light_mode_rounded;
      case ThemeMode.dark:
        return Icons.dark_mode_rounded;
      case ThemeMode.system:
        return Icons.brightness_auto_rounded;
    }
  }

  void toggleTheme() => cycleTheme();

  void cycleTheme() {
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
    notifyListeners();
  }
}