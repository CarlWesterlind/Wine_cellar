import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The app language. Null [locale] means follow the device language.
class SettingsController extends ChangeNotifier {
  SettingsController(this._prefs) {
    final code = _prefs.getString(_localeKey);
    _locale = code == null ? null : Locale(code);
  }

  static const _localeKey = 'locale';

  final SharedPreferences _prefs;
  Locale? _locale;

  Locale? get locale => _locale;

  Future<void> setLocale(Locale? locale) async {
    _locale = locale;
    notifyListeners();
    if (locale == null) {
      await _prefs.remove(_localeKey);
    } else {
      await _prefs.setString(_localeKey, locale.languageCode);
    }
  }
}
