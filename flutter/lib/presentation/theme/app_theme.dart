import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_component_theme.dart';
import 'app_semantic_colors.dart';
import 'app_typography.dart';
import 'app_spacing.dart';

abstract final class AppTheme {
  static ThemeData get light => _buildTheme(
    ColorScheme.fromSeed(
      seedColor: AppColors.blue700,
      brightness: Brightness.light,
    ),
    AppSemanticColors.light,
  );

  static ThemeData get dark => _buildTheme(
    ColorScheme.fromSeed(
      seedColor: AppColors.blue300,
      brightness: Brightness.dark,
    ),
    AppSemanticColors.dark,
  );

  static ThemeData _buildTheme(
    ColorScheme scheme,
    AppSemanticColors semantic,
  ) => ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    textTheme: AppTypography.textTheme,
    scaffoldBackgroundColor: semantic.surface,
    extensions: <ThemeExtension<dynamic>>[semantic, AppComponentTheme.standard],
    appBarTheme: AppBarTheme(
      backgroundColor: semantic.surface,
      foregroundColor: semantic.onSurface,
      elevation: AppComponentTheme.standard.appBarElevation,
      titleTextStyle: AppTypography.textTheme.titleLarge?.copyWith(
        color: semantic.onSurface,
      ),
    ),
    cardTheme: CardThemeData(
      color: semantic.surfaceElevated,
      elevation: AppComponentTheme.standard.cardElevation,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          AppComponentTheme.standard.cardRadius,
        ),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: semantic.surfaceElevated,
      height: AppComponentTheme.standard.navigationBarHeight,
      labelTextStyle: WidgetStatePropertyAll(
        AppTypography.textTheme.labelMedium?.copyWith(
          color: semantic.onSurface,
        ),
      ),
    ),
    iconButtonTheme: const IconButtonThemeData(
      style: ButtonStyle(
        minimumSize: WidgetStatePropertyAll(
          Size(AppSpacing.space48, AppSpacing.space48),
        ),
        tapTargetSize: MaterialTapTargetSize.padded,
      ),
    ),
    filledButtonTheme: const FilledButtonThemeData(
      style: ButtonStyle(
        minimumSize: WidgetStatePropertyAll(Size(0, AppSpacing.space48)),
      ),
    ),
    textButtonTheme: const TextButtonThemeData(
      style: ButtonStyle(
        minimumSize: WidgetStatePropertyAll(Size(0, AppSpacing.space48)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: semantic.surfaceElevated,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          AppComponentTheme.standard.inputRadius,
        ),
      ),
    ),
  );
}
