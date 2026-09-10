import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // ── Brand palette ──────────────────────────────────────────────────
  static const Color primaryLight    = Color(0xFF7C3AED); // Violet-600
  static const Color primaryDark     = Color(0xFF9F6EFF); // Lighter violet for dark bg
  static const Color secondaryColor  = Color(0xFF06B6D4); // Cyan-500
  static const Color accentPink      = Color(0xFFEC4899); // Pink-500

  // Light surface stack
  static const Color bgLight         = Color(0xFFF5F3FF); // Faint lavender white
  static const Color surfaceLight    = Color(0xFFFFFFFF);
  static const Color surfaceLight2   = Color(0xFFF0EBFF); // Card surface

  // Dark surface stack
  static const Color bgDark          = Color(0xFF0F0D1A); // Near-black purple
  static const Color surfaceDark     = Color(0xFF1A1728); // Dark card
  static const Color surfaceDark2    = Color(0xFF221F35); // Elevated dark card

  // Text
  static const Color textPrimLight   = Color(0xFF1E1B4B);
  static const Color textSecLight    = Color(0xFF6B7280);
  static const Color textPrimDark    = Color(0xFFF1F0FF);
  static const Color textSecDark     = Color(0xFF9CA3AF);

  static const Color errorColor      = Color(0xFFEF4444);

  // ── Gradient helpers ───────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkBgGradient = LinearGradient(
    colors: [Color(0xFF0F0D1A), Color(0xFF1A0F2E)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static LinearGradient avatarGradient(int seed) {
    final List<List<Color>> palettes = [
      [Color(0xFF7C3AED), Color(0xFF4F46E5)],
      [Color(0xFF06B6D4), Color(0xFF0EA5E9)],
      [Color(0xFFEC4899), Color(0xFFF43F5E)],
      [Color(0xFF10B981), Color(0xFF059669)],
      [Color(0xFFF59E0B), Color(0xFFEF4444)],
      [Color(0xFF8B5CF6), Color(0xFFEC4899)],
    ];
    final idx = seed.abs() % palettes.length;
    return LinearGradient(
      colors: palettes[idx],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  // ── Light Theme ────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryLight,
      scaffoldBackgroundColor: bgLight,
      colorScheme: const ColorScheme.light(
        primary: primaryLight,
        secondary: secondaryColor,
        tertiary: accentPink,
        surface: surfaceLight,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimLight,
        onError: Colors.white,
        surfaceContainerLowest: Color(0xFFFBFAFF),
        surfaceContainerLow: surfaceLight2,
        surfaceContainer: Color(0xFFEDE9FF),
        outline: Color(0xFFD1C4FF),
      ),
      fontFamily: 'Inter',
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: textPrimLight),
        titleTextStyle: const TextStyle(
          color: textPrimLight,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        shape: Border(
          bottom: BorderSide(color: const Color(0xFFE5E0FF), width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryLight,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.2),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLight2,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE5E0FF), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: errorColor, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        labelStyle: const TextStyle(color: textSecLight),
        hintStyle: const TextStyle(color: textSecLight),
        prefixIconColor: primaryLight,
      ),
      cardTheme: CardThemeData(
        color: surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFEDE9FF), width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceLight2,
        selectedColor: primaryLight,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: const BorderSide(color: Color(0xFFD1C4FF), width: 1),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: textPrimLight, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -1),
        displayMedium: TextStyle(color: textPrimLight, fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.5),
        headlineLarge: TextStyle(color: textPrimLight, fontSize: 24, fontWeight: FontWeight.w700),
        headlineMedium: TextStyle(color: textPrimLight, fontSize: 20, fontWeight: FontWeight.w700),
        titleLarge: TextStyle(color: textPrimLight, fontSize: 18, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: textPrimLight, fontSize: 16, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: textPrimLight, fontSize: 16, height: 1.5),
        bodyMedium: TextStyle(color: textSecLight, fontSize: 14, height: 1.4),
        bodySmall: TextStyle(color: textSecLight, fontSize: 12),
        labelLarge: TextStyle(color: textPrimLight, fontSize: 14, fontWeight: FontWeight.w600),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        minLeadingWidth: 0,
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFFEDE9FF), thickness: 1, space: 1),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryLight,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: StadiumBorder(),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textPrimLight,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Dark Theme ─────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryDark,
      scaffoldBackgroundColor: bgDark,
      colorScheme: const ColorScheme.dark(
        primary: primaryDark,
        secondary: secondaryColor,
        tertiary: accentPink,
        surface: surfaceDark,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimDark,
        onError: Colors.white,
        surfaceContainerLowest: Color(0xFF120F20),
        surfaceContainerLow: surfaceDark,
        surfaceContainer: surfaceDark2,
        outline: Color(0xFF3D3560),
      ),
      fontFamily: 'Inter',
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: textPrimDark),
        titleTextStyle: const TextStyle(
          color: textPrimDark,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
        shape: Border(
          bottom: BorderSide(color: const Color(0xFF2A2645), width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryDark,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.2),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceDark2,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF3D3560), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryDark, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: errorColor, width: 1.5),
        ),
        labelStyle: const TextStyle(color: textSecDark),
        hintStyle: const TextStyle(color: textSecDark),
        prefixIconColor: primaryDark,
      ),
      cardTheme: CardThemeData(
        color: surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF2A2645), width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceDark2,
        selectedColor: primaryDark,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textPrimDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: const BorderSide(color: Color(0xFF3D3560), width: 1),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: textPrimDark, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -1),
        displayMedium: TextStyle(color: textPrimDark, fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.5),
        headlineLarge: TextStyle(color: textPrimDark, fontSize: 24, fontWeight: FontWeight.w700),
        headlineMedium: TextStyle(color: textPrimDark, fontSize: 20, fontWeight: FontWeight.w700),
        titleLarge: TextStyle(color: textPrimDark, fontSize: 18, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: textPrimDark, fontSize: 16, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: textPrimDark, fontSize: 16, height: 1.5),
        bodyMedium: TextStyle(color: textSecDark, fontSize: 14, height: 1.4),
        bodySmall: TextStyle(color: textSecDark, fontSize: 12),
        labelLarge: TextStyle(color: textPrimDark, fontSize: 14, fontWeight: FontWeight.w600),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        minLeadingWidth: 0,
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFF2A2645), thickness: 1, space: 1),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryDark,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: StadiumBorder(),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceDark2,
        contentTextStyle: const TextStyle(color: textPrimDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
