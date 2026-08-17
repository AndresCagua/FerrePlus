import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get light {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF1565C0),
      primary: const Color(0xFF1565C0),
      secondary: const Color(0xFFFF7043),
      surface: const Color(0xFFFFFFFF),
    );
    return ThemeData(colorScheme: scheme, useMaterial3: true);
  }

  static ThemeData get dark {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF64B5F6),
      brightness: Brightness.dark,
      secondary: const Color(0xFFFF8A65),
    );
    return ThemeData(colorScheme: scheme, useMaterial3: true);
  }
}
