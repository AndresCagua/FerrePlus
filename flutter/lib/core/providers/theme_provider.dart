import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/services/theme_preference_store.dart';
import '../theme/theme_mode.dart';

final themePreferenceStoreProvider = Provider<ThemePreferenceStore>((ref) {
  return InMemoryThemePreferenceStore();
});

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  late final ThemePreferenceStore _store;
  bool _hasManualSelection = false;

  @override
  ThemeMode build() {
    _store = ref.watch(themePreferenceStoreProvider);
    Future<void>.microtask(_restorePreference);
    return ThemeMode.system;
  }

  Future<void> setMode(AppThemeMode mode) async {
    _hasManualSelection = true;
    state = mode.materialMode;
    await _store.write(mode);
  }

  Future<void> _restorePreference() async {
    final AppThemeMode preference = await _store.read();
    if (_hasManualSelection) return;
    state = preference.materialMode;
  }
}

Future<ProviderContainer> createAppContainer() async {
  final SharedPreferences preferences = await SharedPreferences.getInstance();
  return ProviderContainer(
      overrides: [
      themePreferenceStoreProvider.overrideWithValue(
        SharedPreferencesThemePreferenceStore(preferences),
      ),
    ],
  );
}
