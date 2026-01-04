import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Warm neutral color palette inspired by the design
  static const Color _warmBeige = Color(0xFFF5F1EB);
  static const Color _creamWhite = Color(0xFFFAF8F5);
  static const Color _darkCharcoal = Color(0xFF2C2C2E);
  static const Color _softCharcoal = Color(0xFF3A3A3C);
  static const Color _goldenAccent = Color(0xFFD4A574);
  static const Color _warmGold = Color(0xFFB8956A);
  static const Color _lightGray = Color(0xFFE8E5E0);
  static const Color _textDark = Color(0xFF1C1C1E);
  static const Color _textMedium = Color(0xFF48484A);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _goldenAccent,
        brightness: Brightness.light,
        primary: _goldenAccent,
        secondary: _warmGold,
        surface: _creamWhite,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: _textDark,
      ),
      textTheme: GoogleFonts.interTextTheme(
        TextTheme(
          headlineLarge: GoogleFonts.inter(
            color: _textDark,
            fontWeight: FontWeight.w700,
          ),
          headlineMedium: GoogleFonts.inter(
            color: _textDark,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: GoogleFonts.inter(
            color: _textDark,
            fontWeight: FontWeight.w400,
          ),
          bodyMedium: GoogleFonts.inter(
            color: _textMedium,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
      scaffoldBackgroundColor: _warmBeige,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 25,
          fontWeight: FontWeight.w700,
          color: _textDark,
        ),
        iconTheme: const IconThemeData(color: _textDark),
      ),
      cardTheme: CardThemeData(
        color: _creamWhite,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _darkCharcoal,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _darkCharcoal,
          side: const BorderSide(color: _lightGray, width: 1.5),
          backgroundColor: _creamWhite,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _creamWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _lightGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _lightGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _goldenAccent, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _goldenAccent,
        brightness: Brightness.dark,
        primary: _goldenAccent,
        secondary: _warmGold,
        surface: _darkCharcoal,
        onPrimary: _darkCharcoal,
        onSecondary: _darkCharcoal,
        onSurface: _creamWhite,
      ),
      textTheme: GoogleFonts.interTextTheme(
        TextTheme(
          headlineLarge: GoogleFonts.inter(
            color: _creamWhite,
            fontWeight: FontWeight.w700,
          ),
          headlineMedium: GoogleFonts.inter(
            color: _creamWhite,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: GoogleFonts.inter(
            color: _creamWhite,
            fontWeight: FontWeight.w400,
          ),
          bodyMedium: GoogleFonts.inter(
            color: const Color(0xFFAEAEB2),
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
      scaffoldBackgroundColor: const Color(0xFF1C1C1E),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 25,
          fontWeight: FontWeight.w700,
          color: _creamWhite,
        ),
        iconTheme: const IconThemeData(color: _creamWhite),
      ),
      cardTheme: CardThemeData(
        color: _darkCharcoal,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _goldenAccent,
          foregroundColor: _darkCharcoal,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _creamWhite,
          side: const BorderSide(color: _softCharcoal, width: 1.5),
          backgroundColor: _darkCharcoal,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkCharcoal,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _softCharcoal),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _softCharcoal),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _goldenAccent, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}
