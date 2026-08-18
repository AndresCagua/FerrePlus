import 'package:flutter/material.dart';

import 'app_colors.dart';

@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.primary,
    required this.onPrimary,
    required this.surface,
    required this.surfaceElevated,
    required this.onSurface,
    required this.textSecondary,
    required this.success,
    required this.warning,
    required this.error,
    required this.outline,
    required this.kpiPurple,
    required this.kpiTeal,
    required this.kpiAmber,
    required this.successContainer,
    required this.errorContainer,
  });

  final Color primary;
  final Color onPrimary;
  final Color surface;
  final Color surfaceElevated;
  final Color onSurface;
  final Color textSecondary;
  final Color success;
  final Color warning;
  final Color error;
  final Color outline;
  final Color kpiPurple;
  final Color kpiTeal;
  final Color kpiAmber;
  final Color successContainer;
  final Color errorContainer;

  static AppSemanticColors of(BuildContext context) {
    final AppSemanticColors? colors = Theme.of(
      context,
    ).extension<AppSemanticColors>();
    if (colors != null) return colors;
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }

  static const AppSemanticColors light = AppSemanticColors(
    primary: AppColors.blue700,
    onPrimary: AppColors.white,
    surface: AppColors.white,
    surfaceElevated: AppColors.slate50,
    onSurface: AppColors.slate950,
    textSecondary: AppColors.slate700,
    success: AppColors.success,
    warning: AppColors.warning,
    error: AppColors.error,
    outline: AppColors.slate100,
    kpiPurple: AppColors.kpiPurple,
    kpiTeal: AppColors.kpiTeal,
    kpiAmber: AppColors.kpiAmberAccessible,
    successContainer: AppColors.successContainerLight,
    errorContainer: AppColors.errorContainerLight,
  );

  static const AppSemanticColors dark = AppSemanticColors(
    primary: AppColors.blue300,
    onPrimary: AppColors.slate950,
    surface: AppColors.slate950,
    surfaceElevated: AppColors.slate900,
    onSurface: AppColors.white,
    textSecondary: AppColors.slate100,
    success: AppColors.successDark,
    warning: AppColors.warningDark,
    error: AppColors.errorDark,
    outline: AppColors.slate100,
    kpiPurple: AppColors.coral300,
    kpiTeal: AppColors.blue300,
    kpiAmber: AppColors.warningDark,
    successContainer: AppColors.successContainerDark,
    errorContainer: AppColors.errorContainerDark,
  );

  @override
  AppSemanticColors copyWith({
    Color? primary,
    Color? onPrimary,
    Color? surface,
    Color? onSurface,
  }) => AppSemanticColors(
    primary: primary ?? this.primary,
    onPrimary: onPrimary ?? this.onPrimary,
    surface: surface ?? this.surface,
    surfaceElevated: surfaceElevated,
    onSurface: onSurface ?? this.onSurface,
    textSecondary: textSecondary,
    success: success,
    warning: warning,
    error: error,
    outline: outline,
    kpiPurple: kpiPurple,
    kpiTeal: kpiTeal,
    kpiAmber: kpiAmber,
    successContainer: successContainer,
    errorContainer: errorContainer,
  );

  @override
  AppSemanticColors lerp(covariant AppSemanticColors? other, double t) =>
      other == null
      ? this
      : AppSemanticColors(
          primary: Color.lerp(primary, other.primary, t)!,
          onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
          surface: Color.lerp(surface, other.surface, t)!,
          surfaceElevated: Color.lerp(
            surfaceElevated,
            other.surfaceElevated,
            t,
          )!,
          onSurface: Color.lerp(onSurface, other.onSurface, t)!,
          textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
          success: Color.lerp(success, other.success, t)!,
          warning: Color.lerp(warning, other.warning, t)!,
          error: Color.lerp(error, other.error, t)!,
          outline: Color.lerp(outline, other.outline, t)!,
          kpiPurple: Color.lerp(kpiPurple, other.kpiPurple, t)!,
          kpiTeal: Color.lerp(kpiTeal, other.kpiTeal, t)!,
          kpiAmber: Color.lerp(kpiAmber, other.kpiAmber, t)!,
          successContainer: Color.lerp(
            successContainer,
            other.successContainer,
            t,
          )!,
          errorContainer: Color.lerp(errorContainer, other.errorContainer, t)!,
        );
}
