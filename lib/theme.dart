import 'package:flutter/material.dart';

/// Uygulamanın açık/koyu Material 3 teması.
class AppTheme {
  static const Color _seed = Color(0xFF5B4B8A);

  static ThemeData light() => _base(Brightness.light);
  static ThemeData dark() => _base(Brightness.dark);

  static ThemeData _base(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(seedColor: _seed, brightness: brightness);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      appBarTheme: const AppBarTheme(centerTitle: false),
    );
  }
}
