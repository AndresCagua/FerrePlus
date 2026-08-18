import 'package:flutter/material.dart';

abstract final class AppTypography {
  static const String fontFamily = 'Roboto';
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight bold = FontWeight.w700;
  static const double display = 32;
  static const double headline = 24;
  static const double title = 20;
  static const double body = 16;
  static const double label = 14;
  static const double caption = 12;

  static TextTheme get textTheme => const TextTheme(
    displaySmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: display,
      fontWeight: regular,
    ),
    headlineSmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: headline,
      fontWeight: medium,
    ),
    titleLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: title,
      fontWeight: medium,
    ),
    bodyLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: body,
      fontWeight: regular,
    ),
    bodyMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: label,
      fontWeight: regular,
    ),
    labelLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: label,
      fontWeight: medium,
    ),
    bodySmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: caption,
      fontWeight: regular,
    ),
  );
}
