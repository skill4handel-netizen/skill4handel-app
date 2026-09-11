import 'package:flutter/material.dart';

class AppColors {
  static const blue = Color(0xFF2EA3F2);
  static const green = Color(0xFF4CC84A);
  static const gold = Color(0xFFF0C21A);
  static const ink = Color(0xFF111111);
  static const text = Color(0xFF16324A);
  static const muted = Color(0xFF6B7C8A);
  static const line = Color(0xFFD7E3EC);
  static const soft = Color(0xFFEFF7FF);
}

class AppTheme {
  static ButtonStyle solid(Color color) {
    return ElevatedButton.styleFrom(
      backgroundColor: color,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.blue, primary: AppColors.blue),
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.blue,
        primary: AppColors.blue,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF0E1620),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF102030),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
    );
  }
}