import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/theme_provider.dart';
import '../../../core/theme/theme_mode.dart';
import '../../theme/app_typography.dart';

class MasThemeSelector extends ConsumerWidget {
  const MasThemeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeMode activeMode = ref.watch(themeModeProvider);
    final AppThemeMode selected = switch (activeMode) {
      ThemeMode.light => AppThemeMode.light,
      ThemeMode.dark => AppThemeMode.dark,
      ThemeMode.system => AppThemeMode.system,
    };
    return RadioGroup<AppThemeMode>(
      groupValue: selected,
      onChanged: (AppThemeMode? mode) {
        if (mode != null) ref.read(themeModeProvider.notifier).setMode(mode);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Tema',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: AppTypography.medium),
          ),
          const RadioListTile<AppThemeMode>(
            value: AppThemeMode.light,
            title: Text('Claro'),
          ),
          const RadioListTile<AppThemeMode>(
            value: AppThemeMode.dark,
            title: Text('Oscuro'),
          ),
          const RadioListTile<AppThemeMode>(
            value: AppThemeMode.system,
            title: Text('Seguir sistema'),
          ),
        ],
      ),
    );
  }
}
