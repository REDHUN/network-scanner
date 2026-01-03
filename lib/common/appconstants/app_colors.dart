import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors
  static const Color primary = Color(0xFF1E88E5);
  static const Color primaryDark = Color(0xFF1565C0);
  static const Color secondary = Color(0xFF00BCD4);
  static const Color secondarySoft = Color(0xFF26C6DA);

  // Backgrounds
  static const Color scaffoldBackground = Color(0xFF0B0F1A);
  static const Color pageBackground = Color(0xFF0E1320);
  static const Color surface = Color(0xFF141A2A);
  static const Color surfaceElevated = Color(0xFF1A2236);
  static const Color divider = Color(0xFF222A3D);

  // Buttons
  static const Color buttonPrimary = Color(0xFF1E88E5);
  static const Color buttonPrimaryPressed = Color(0xFF1976D2);
  static const Color danger = Color(0xFF8E1B1B);

  // Status
  static const Color success = Color(0xFF2ECC71);
  static const Color offline = Color(0xFF7A8194);
  static const Color warning = Color(0xFFFBC02D);
  static const Color error = Color(0xFFE53935);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B7C3);
  static const Color textMuted = Color(0xFF7A8194);
  static const Color textDisabled = Color(0xFF5A6072);
  static const Color textLink = Color(0xFF42A5F5);

  // Icons
  static const Color iconPrimary = Color(0xFF42A5F5);
  static const Color iconSecondary = Color(0xFF8FA3C8);
  static const Color iconInactive = Color(0xFF5A6072);

  static const Color white = Color(0xFFFFFFFF);
  static const Color white54 = Color(0x8AFFFFFF);
  static const Color white10 = Color(0x1AFFFFFF);
  static const Color white12 = Color(0x1FFFFFFF);
  static const Color white24 = Color(0x3DFFFFFF);
  static const Color white50 = Color(0x80FFFFFF);
  static const Color white60 = Color(0x99FFFFFF);
  static const Color white70 = Color(0xB3FFFFFF);
  static const Color white80 = Color(0xCCFFFFFF);
  static const Color white90 = Color(0xE6FFFFFF);
  static const Color white97 = Color(0xF2FFFFFF);

  static const Color black54 = Color(0x8A000000);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Color(0x00000000);
  static const Color grey = Color(0xFF808080);
  static const Color lightGrey = Color(0xFFE0E0E0);
  static const Color darkGrey = Color(0xFF404040);

  static const Color green = Color(0xFF2ECC71);
  static const Color greenAccent = Color(0xFF2ECC71);
  static const Color orange = Color(0xFFF39C12);
  static const Color red = Color(0xFFE53935);
  static const Color redAccent = Color(0xFFE53935);
  static const Color yellow = Color(0xFFFBC02D);
  static const Color blue = Color(0xFF1E88E5);

  static const Gradient commonContainerGradient = LinearGradient(
    colors: [Color(0xFF1A2233), Color(0xFF0F1724)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
