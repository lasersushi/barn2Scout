import 'package:flutter/material.dart';

/// Barn2Scout visual theme — Barn2 Robotics blue, Material 3, light + dark.
/// Dark mode matters: scouting happens in dim gyms on dim-screen phones.
class AppTheme {
  AppTheme._();

  /// Barn2 blue — sampled from the Barn2 Robotics logo stripe.
  static const Color seed = Color(0xFF0060A7);

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
      navigationBarTheme: NavigationBarThemeData(
        height: 60,
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
