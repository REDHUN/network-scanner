import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ip_tools/common/appconstants/app_colors.dart';

class AppTheme {
  // Keep the original brand blue while using Material 3 Expressive tonal surfaces.
  static const Color _primaryBlue = AppColors.primary;
  static const Color _backgroundLight = Color(0xFFF7F8FC);
  static const Color _cardLight = Colors.white;
  static const Color _textDark = Color(0xFF0F172A);
  static const Color _textMedium = Color(0xFF64748B);
  static const Color _borderLight = Color(0xFFE2E8F0);

  static const Color _backgroundDark = Color(0xFF0F172A);
  static const Color _cardDark = Color(0xFF1E293B);
  static const Color _textLight = Color(0xFFF8FAFC);
  static const Color _textMuted = Color(0xFF94A3B8);
  static const Color _borderDark = Color(0xFF334155);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: _primaryBlue,
            dynamicSchemeVariant: DynamicSchemeVariant.expressive,
            brightness: Brightness.light,
          ).copyWith(
            primary: _primaryBlue,
            onPrimary: Colors.white,
            primaryContainer: const Color(0xFFE4F1FF),
            onPrimaryContainer: const Color(0xFF003E80),
            secondary: _primaryBlue,
            onSecondary: Colors.white,
            secondaryContainer: const Color(0xFFE4F1FF),
            onSecondaryContainer: const Color(0xFF003E80),
            surfaceTint: _primaryBlue,
          ),
      textTheme: GoogleFonts.interTextTheme(
        TextTheme(
          displaySmall: GoogleFonts.inter(
            color: _textDark,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.2,
          ),
          headlineSmall: GoogleFonts.inter(
            color: _textDark,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.6,
          ),
          titleLarge: GoogleFonts.inter(
            color: _textDark,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
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
      scaffoldBackgroundColor: _backgroundLight,
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _cardLight,
        indicatorColor: const Color(0xFFE4F1FF),
        indicatorShape: const StadiumBorder(),
        height: 78,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => GoogleFonts.inter(
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? _primaryBlue
                : _textMedium,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected)
                ? _primaryBlue
                : _textMedium,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: _cardLight,
        selectedColor: const Color(0xFFE4F1FF),
        side: BorderSide.none,
        shape: const StadiumBorder(),
        labelStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          color: _textDark,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: _primaryBlue,
        linearTrackColor: Color(0xFFE5E9F6),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: const StadiumBorder(),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE5E8F1),
        thickness: 1,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: _backgroundLight,
        elevation: 0,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: _textDark,
        ),
        iconTheme: const IconThemeData(color: _textDark),
      ),
      cardTheme: CardThemeData(
        color: _cardLight,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.04),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: const BorderSide(color: _borderLight, width: 0.8),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 10,
        shadowColor: Colors.black.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
        ),
        textStyle: GoogleFonts.inter(
          color: _textDark,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _textDark,
          side: const BorderSide(color: _borderLight, width: 1.5),
          backgroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _primaryBlue, width: 2),
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
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: _primaryBlue,
            dynamicSchemeVariant: DynamicSchemeVariant.expressive,
            brightness: Brightness.dark,
          ).copyWith(
            primary: _primaryBlue,
            onPrimary: Colors.white,
            primaryContainer: const Color(0xFF173E70),
            onPrimaryContainer: Colors.white,
            secondary: _primaryBlue,
            onSecondary: Colors.white,
            secondaryContainer: const Color(0xFF173E70),
            onSecondaryContainer: Colors.white,
            surfaceTint: _primaryBlue,
          ),
      textTheme: GoogleFonts.interTextTheme(
        TextTheme(
          headlineLarge: GoogleFonts.inter(
            color: _textLight,
            fontWeight: FontWeight.w700,
          ),
          headlineMedium: GoogleFonts.inter(
            color: _textLight,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: GoogleFonts.inter(
            color: _textLight,
            fontWeight: FontWeight.w400,
          ),
          bodyMedium: GoogleFonts.inter(
            color: _textMuted,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
      scaffoldBackgroundColor: _backgroundDark,
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _cardDark,
        indicatorColor: const Color(0xFF173E70),
        indicatorShape: const StadiumBorder(),
        height: 78,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => GoogleFonts.inter(
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? _textLight
                : _textMuted,
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: _backgroundDark,
        elevation: 0,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: _textLight,
        ),
        iconTheme: const IconThemeData(color: _textLight),
      ),
      cardTheme: CardThemeData(
        color: _cardDark,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: _borderDark, width: 1),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: _cardDark,
        surfaceTintColor: Colors.transparent,
        elevation: 10,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _borderDark, width: 1.2),
        ),
        textStyle: GoogleFonts.inter(
          color: _textLight,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: _cardDark,
        surfaceTintColor: Colors.transparent,
        elevation: 12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _textLight,
          side: const BorderSide(color: _borderDark, width: 1.5),
          backgroundColor: _cardDark,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _cardDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _primaryBlue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}
