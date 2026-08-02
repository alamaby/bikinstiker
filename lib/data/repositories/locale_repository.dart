import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/widgets.dart';

class LocaleRepository {
  static const _localeKey = 'app.locale';
  static const _selectionCompletedKey = 'app.locale.selection_completed';

  static const supportedLanguageCodes = <String>['en', 'id'];
  static const fallbackLocale = Locale('en');

  final SharedPreferences _prefs;

  LocaleRepository(this._prefs);

  /// Locale explicitly chosen by the user, if any.
  Locale? get savedLocale {
    final code = _prefs.getString(_localeKey);
    if (code == null || !supportedLanguageCodes.contains(code)) return null;
    return Locale(code);
  }

  /// Whether the user has completed the first-launch language selection.
  bool get hasSelectionCompleted => _prefs.getBool(_selectionCompletedKey) ?? false;

  /// Active locale: explicit choice wins, then platform locale when it is a
  /// supported language, otherwise English.
  Locale resolveLocale(Locale? platformLocale) {
    final saved = savedLocale;
    if (saved != null) return saved;
    if (platformLocale != null &&
        supportedLanguageCodes.contains(platformLocale.languageCode)) {
      return Locale(platformLocale.languageCode);
    }
    return fallbackLocale;
  }

  Future<void> saveLocale(Locale locale, {bool markSelectionCompleted = true}) async {
    await _prefs.setString(_localeKey, locale.languageCode);
    if (markSelectionCompleted) {
      await _prefs.setBool(_selectionCompletedKey, true);
    }
  }

  Future<void> clearLocale() async {
    await _prefs.remove(_localeKey);
    await _prefs.remove(_selectionCompletedKey);
  }
}
