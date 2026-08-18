import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/theme_mode.dart';

abstract interface class ThemePreferenceStore {
  Future<AppThemeMode> read();
  Future<void> write(AppThemeMode mode);
}

class InMemoryThemePreferenceStore implements ThemePreferenceStore {
  AppThemeMode _mode = AppThemeMode.system;

  @override
  Future<AppThemeMode> read() async => _mode;

  @override
  Future<void> write(AppThemeMode mode) async => _mode = mode;
}

class SharedPreferencesThemePreferenceStore implements ThemePreferenceStore {
  const SharedPreferencesThemePreferenceStore(this._preferences);
  static const String _key = 'ferreplus.theme_mode';
  final SharedPreferences _preferences;

  @override
  Future<AppThemeMode> read() async {
    try {
      return AppThemeModeSerialization.fromStorage(
        _preferences.getString(_key),
      );
    } catch (_) {
      return AppThemeMode.system;
    }
  }

  @override
  Future<void> write(AppThemeMode mode) async {
    try {
      await _preferences.setString(_key, mode.storageValue);
    } catch (_) {
      // La preferencia es opcional; el tema actual permanece en memoria.
    }
  }
}
