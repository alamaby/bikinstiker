import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user's theme preference (system/light/dark) and exposes it to
/// MaterialApp via [themeMode]. Default follows the system.
class ThemeCubit extends Cubit<ThemeMode> {
  static const String _prefKey = 'theme_mode';

  final SharedPreferences _prefs;

  ThemeCubit(this._prefs) : super(ThemeMode.system) {
    _restore();
  }

  void _restore() {
    switch (_prefs.getString(_prefKey)) {
      case 'light':
        emit(ThemeMode.light);
      case 'dark':
        emit(ThemeMode.dark);
      default:
        emit(ThemeMode.system);
    }
  }

  void setMode(ThemeMode mode) {
    _prefs.setString(_prefKey, mode.name);
    emit(mode);
  }
}
