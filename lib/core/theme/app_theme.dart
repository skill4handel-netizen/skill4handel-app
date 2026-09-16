import 'package:flutter/material.dart';

class AppColors {
  static const blue = Color(0xFF2EA3F2);
  static const blueDeep = Color(0xFF1578C8);
  static const green = Color(0xFF4CC84A);
  static const gold = Color(0xFFF0C21A);
  static const purple = Color(0xFF7B61FF);
  static const coral = Color(0xFFFF6B57);
  static const ink = Color(0xFF111111);
  static const text = Color(0xFF16324A);
  static const muted = Color(0xFF6B7C8A);
  static const line = Color(0xFFD7E3EC);
  static const soft = Color(0xFFEFF7FF);
  static const mint = Color(0xFFE8F9E8);
  static const cream = Color(0xFFFFF6D8);
}

class AppTheme {
  static ButtonStyle solid(Color color) {
    return ElevatedButton.styleFrom(
      backgroundColor: color,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  static BoxDecoration card({Color color = Colors.white}) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(24),
      boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 6))],
    );
  }

  static const headerGradient = LinearGradient(
    colors: [Color(0xFF2EA3F2), Color(0xFF7B61FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.blue, primary: AppColors.blue),
      scaffoldBackgroundColor: const Color(0xFFF5FAFF),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.soft,
        selectedColor: AppColors.blue,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
