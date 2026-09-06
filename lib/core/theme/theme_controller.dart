import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stores the user's app theme preference. Light mode is the default.
class ThemeController extends ChangeNotifier {
  static const _themeModeKey = 'app_theme_mode';

  ThemeController(this._preferences) {
    _themeMode = _preferences.getString(_themeModeKey) == 'dark'
        ? ThemeMode.dark
        : ThemeMode.light;
  }

  final SharedPreferences _preferences;
  late ThemeMode _themeMode;

  ThemeMode get themeMode => _themeMode;

  Future<void> setThemeMode(ThemeMode themeMode) async {
    if (_themeMode == themeMode) return;
    _themeMode = themeMode;
    await _preferences.setString(
      _themeModeKey,
      themeMode == ThemeMode.dark ? 'dark' : 'light',
    );
    notifyListeners();
  }
}
