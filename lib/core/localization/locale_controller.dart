import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stores an optional app locale. A null locale follows the device setting.
class LocaleController extends ChangeNotifier {
  static const _localeKey = 'app_locale';

  LocaleController(this._preferences) {
    final languageCode = _preferences.getString(_localeKey);
    _locale = languageCode == null ? null : Locale(languageCode);
  }

  final SharedPreferences _preferences;
  Locale? _locale;

  Locale? get locale => _locale;

  Future<void> setLocale(Locale? locale) async {
    if (_locale == locale) return;
    _locale = locale;
    if (locale == null) {
      await _preferences.remove(_localeKey);
    } else {
      await _preferences.setString(_localeKey, locale.languageCode);
    }
    notifyListeners();
  }
}
