import 'package:flutter/material.dart';

class AppTheme {
  static const Color govRed = Color(0xFF8F1D21);
  static const Color govBlack = Color(0xFF151515);
  static const Color paper = Color(0xFFF6F6F6);

  static ThemeData get governmentTheme {
    final base = ThemeData(useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: govRed,
        primary: govRed,
        secondary: govBlack,
        background: paper,
      ),
      scaffoldBackgroundColor: paper,
      appBarTheme: const AppBarTheme(
        backgroundColor: govBlack,
        foregroundColor: Colors.white,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
