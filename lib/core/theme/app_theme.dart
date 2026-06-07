import 'package:flutter/material.dart';

/// Barn2Scout visual theme — Team 751 green, Material 3, light + dark.
/// Dark mode matters: scouting happens in dim gyms on dim-screen phones.
class AppTheme {
  AppTheme._();

  /// Barn2 green.
  static const Color seed = Color(0xFF2E7D32);

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surfaceContainer,
        centerTitle: false,
      ),
    );
  }
}
