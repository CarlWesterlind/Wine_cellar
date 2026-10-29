import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The user's choices for language and light/dark appearance, remembered
/// between app starts.
class AppSettings extends ChangeNotifier {
  AppSettings(this._prefs) {
    final code = _prefs.getString(_localeKey);
    _locale = code == null ? null : Locale(code);
    _themeMode =
        ThemeMode.values.asNameMap()[_prefs.getString(_themeKey)] ??
        ThemeMode.system;
  }

  static const _localeKey = 'locale';
  static const _themeKey = 'theme';

  final SharedPreferences _prefs;
  Locale? _locale;
  late ThemeMode _themeMode;

  /// Null means follow the device language.
  Locale? get locale => _locale;

  /// [ThemeMode.system] follows the phone's light/dark setting.
  ThemeMode get themeMode => _themeMode;

  Future<void> setLocale(Locale? locale) async {
    _locale = locale;
    notifyListeners();
    if (locale == null) {
      await _prefs.remove(_localeKey);
    } else {
      await _prefs.setString(_localeKey, locale.languageCode);
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    await _prefs.setString(_themeKey, mode.name);
  }
}
