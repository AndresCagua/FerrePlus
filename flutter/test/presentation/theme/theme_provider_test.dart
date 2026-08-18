import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ferreplus/core/providers/theme_provider.dart';
import 'package:ferreplus/core/theme/theme_mode.dart';
import 'package:ferreplus/data/services/theme_preference_store.dart';
import 'package:ferreplus/presentation/shared/widgets/theme_selector.dart';
import 'package:ferreplus/presentation/theme/app_component_theme.dart';
import 'package:ferreplus/presentation/theme/app_semantic_colors.dart';
import 'package:ferreplus/presentation/theme/app_theme.dart';

class FakeThemePreferenceStore implements ThemePreferenceStore {
  AppThemeMode value = AppThemeMode.system;

  @override
  Future<AppThemeMode> read() async => value;

  @override
  Future<void> write(AppThemeMode mode) async => value = mode;
}

void main() {
  test('theme mode defaults to system and persists changes', () async {
    final FakeThemePreferenceStore store = FakeThemePreferenceStore();
    final ProviderContainer container = ProviderContainer(
      overrides: [themePreferenceStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);

    expect(container.read(themeModeProvider), ThemeMode.system);
    await container.read(themeModeProvider.notifier).setMode(AppThemeMode.dark);
    expect(container.read(themeModeProvider), ThemeMode.dark);
    expect(store.value, AppThemeMode.dark);
    await container.read(themeModeProvider.notifier).setMode(AppThemeMode.light);
    expect(container.read(themeModeProvider), ThemeMode.light);
    await container.read(themeModeProvider.notifier).setMode(AppThemeMode.system);
    expect(container.read(themeModeProvider), ThemeMode.system);
  });

  test('invalid persisted values fall back to system', () {
    expect(AppThemeModeSerialization.fromStorage('invalid'), AppThemeMode.system);
    expect(AppThemeModeSerialization.fromStorage(null), AppThemeMode.system);
  });

  test('themes expose semantic and component extensions', () {
    final AppSemanticColors light = AppTheme.light.extension<AppSemanticColors>()!;
    final AppSemanticColors dark = AppTheme.dark.extension<AppSemanticColors>()!;
    expect(light.surface, isNot(dark.surface));
    expect(light.onSurface, isNot(dark.onSurface));
    expect(AppTheme.light.extension<AppComponentTheme>(), isNotNull);
  });

  testWidgets('theme selector exposes three options and updates selection', (WidgetTester tester) async {
    final FakeThemePreferenceStore store = FakeThemePreferenceStore();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [themePreferenceStoreProvider.overrideWithValue(store)],
        child: MaterialApp(theme: AppTheme.light, home: const Scaffold(body: ThemeSelector())),
      ),
    );
    expect(find.text('Claro'), findsOneWidget);
    expect(find.text('Oscuro'), findsOneWidget);
    expect(find.text('Seguir sistema'), findsOneWidget);
    await tester.tap(find.text('Oscuro'));
    await tester.pump();
    expect(store.value, AppThemeMode.dark);
  });
}
