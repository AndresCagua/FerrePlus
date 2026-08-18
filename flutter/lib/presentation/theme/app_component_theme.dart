import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'app_elevation.dart';
import 'app_radius.dart';
import 'app_spacing.dart';

@immutable
class AppComponentTheme extends ThemeExtension<AppComponentTheme> {
  const AppComponentTheme({
    required this.cardPadding,
    required this.cardRadius,
    required this.cardElevation,
    required this.appBarPadding,
    required this.appBarElevation,
    required this.buttonHeight,
    required this.buttonPadding,
    required this.buttonRadius,
    required this.inputRadius,
    required this.navigationBarHeight,
    required this.dialogRadius,
    required this.bottomSheetRadius,
    required this.snackBarRadius,
  });

  final EdgeInsets cardPadding;
  final double cardRadius;
  final double cardElevation;
  final EdgeInsets appBarPadding;
  final double appBarElevation;
  final double buttonHeight;
  final EdgeInsets buttonPadding;
  final double buttonRadius;
  final double inputRadius;
  final double navigationBarHeight;
  final double dialogRadius;
  final double bottomSheetRadius;
  final double snackBarRadius;

  static const AppComponentTheme standard = AppComponentTheme(
    cardPadding: EdgeInsets.all(AppSpacing.space16),
    cardRadius: AppRadius.medium,
    cardElevation: AppElevation.low,
    appBarPadding: EdgeInsets.symmetric(horizontal: AppSpacing.space16),
    appBarElevation: AppElevation.none,
    buttonHeight: 48,
    buttonPadding: EdgeInsets.symmetric(horizontal: AppSpacing.space16),
    buttonRadius: AppRadius.medium,
    inputRadius: AppRadius.medium,
    navigationBarHeight: 80,
    dialogRadius: AppRadius.extraLarge,
    bottomSheetRadius: AppRadius.extraLarge,
    snackBarRadius: AppRadius.medium,
  );

  @override
  AppComponentTheme copyWith({double? cardRadius, double? buttonHeight}) => AppComponentTheme(
        cardPadding: cardPadding,
        cardRadius: cardRadius ?? this.cardRadius,
        cardElevation: cardElevation,
        appBarPadding: appBarPadding,
        appBarElevation: appBarElevation,
        buttonHeight: buttonHeight ?? this.buttonHeight,
        buttonPadding: buttonPadding,
        buttonRadius: buttonRadius,
        inputRadius: inputRadius,
        navigationBarHeight: navigationBarHeight,
        dialogRadius: dialogRadius,
        bottomSheetRadius: bottomSheetRadius,
        snackBarRadius: snackBarRadius,
      );

  @override
  AppComponentTheme lerp(covariant AppComponentTheme? other, double t) {
    if (other == null) return this;
    return AppComponentTheme(
      cardPadding: EdgeInsets.lerp(cardPadding, other.cardPadding, t)!,
      cardRadius: lerpDouble(cardRadius, other.cardRadius, t)!,
      cardElevation: lerpDouble(cardElevation, other.cardElevation, t)!,
      appBarPadding: EdgeInsets.lerp(appBarPadding, other.appBarPadding, t)!,
      appBarElevation: lerpDouble(appBarElevation, other.appBarElevation, t)!,
      buttonHeight: lerpDouble(buttonHeight, other.buttonHeight, t)!,
      buttonPadding: EdgeInsets.lerp(buttonPadding, other.buttonPadding, t)!,
      buttonRadius: lerpDouble(buttonRadius, other.buttonRadius, t)!,
      inputRadius: lerpDouble(inputRadius, other.inputRadius, t)!,
      navigationBarHeight: lerpDouble(navigationBarHeight, other.navigationBarHeight, t)!,
      dialogRadius: lerpDouble(dialogRadius, other.dialogRadius, t)!,
      bottomSheetRadius: lerpDouble(bottomSheetRadius, other.bottomSheetRadius, t)!,
      snackBarRadius: lerpDouble(snackBarRadius, other.snackBarRadius, t)!,
    );
  }
}
