import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
      minimumSize: const Size.fromHeight(52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      textStyle: GoogleFonts.fredoka(fontWeight: FontWeight.w600, fontSize: 16),
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
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.blue, primary: AppColors.blue),
      scaffoldBackgroundColor: const Color(0xFFF5FAFF),
    );
    return base.copyWith(
      textTheme: GoogleFonts.nunitoTextTheme(base.textTheme).copyWith(
        headlineLarge: GoogleFonts.fredoka(fontSize: 28, fontWeight: FontWeight.w600, color: AppColors.text),
        headlineMedium: GoogleFonts.fredoka(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.text),
        titleLarge: GoogleFonts.fredoka(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.text),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        foregroundColor: Colors.white,
        backgroundColor: AppColors.blue,
        titleTextStyle: GoogleFonts.fredoka(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: AppColors.line)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: AppColors.blue, width: 2)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: solid(AppColors.blue)),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          side: const BorderSide(color: AppColors.blue, width: 1.5),
          foregroundColor: AppColors.blueDeep,
          textStyle: GoogleFonts.fredoka(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFEEE8FF),
        labelStyle: GoogleFonts.nunito(color: const Color(0xFF3D2BB3), fontWeight: FontWeight.w800),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: const BorderSide(color: AppColors.purple),
      ),
    );
  }

  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.blue, primary: AppColors.blue, brightness: Brightness.dark),
      scaffoldBackgroundColor: const Color(0xFF0E1620),
    );
    return base.copyWith(
      textTheme: GoogleFonts.nunitoTextTheme(base.textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF102030),
        foregroundColor: Colors.white,
        titleTextStyle: GoogleFonts.fredoka(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white),
      ),
    );
  }
}

class AppHeader extends StatelessWidget {
  const AppHeader({super.key, required this.title, this.subtitle, this.actions = const []});

  final String title;
  final String? subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 16),
      decoration: const BoxDecoration(gradient: AppTheme.headerGradient),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.fredoka(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w600)),
                  if (subtitle != null) Text(subtitle!, style: GoogleFonts.nunito(color: Colors.white70)),
                ],
              ),
            ),
            ...actions,
          ],
        ),
      ),
    );
  }
}
