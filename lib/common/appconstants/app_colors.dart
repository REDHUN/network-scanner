import 'package:flutter/material.dart';

class AppColors {
  // Warm Neutral Brand Colors
  static const Color primary = Color(0xFFD4A574);
  static const Color primaryDark = Color(0xFFB8956A);
  static const Color secondary = Color(0xFF2C2C2E);
  static const Color secondarySoft = Color(0xFF3A3A3C);

  // Warm Backgrounds
  static const Color scaffoldBackground = Color(0xFFF5F1EB);
  static const Color pageBackground = Color(0xFFFAF8F5);
  static const Color surface = Color(0xFFFAF8F5);
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFE8E5E0);

  // Buttons
  static const Color buttonPrimary = Color(0xFF2C2C2E);
  static const Color buttonPrimaryPressed = Color(0xFF1C1C1E);
  static const Color danger = Color(0xFFD1453B);

  // Status
  static const Color success = Color(0xFF30A46C);
  static const Color offline = Color(0xFF8E8E93);
  static const Color warning = Color(0xFFFF9500);
  static const Color error = Color(0xFFFF3B30);

  // Text
  static const Color textPrimary = Color(0xFF1C1C1E);
  static const Color textSecondary = Color(0xFF48484A);
  static const Color textMuted = Color(0xFF8E8E93);
  static const Color textDisabled = Color(0xFFC7C7CC);
  static const Color textLink = Color(0xFFD4A574);

  // Icons
  static const Color iconPrimary = Color(0xFFD4A574);
  static const Color iconSecondary = Color(0xFF48484A);
  static const Color iconInactive = Color(0xFF8E8E93);

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
  static const Color grey = Color(0xFF8E8E93);
  static const Color lightGrey = Color(0xFFE8E5E0);
  static const Color darkGrey = Color(0xFF48484A);

  static const Color green = Color(0xFF30A46C);
  static const Color greenAccent = Color(0xFF30A46C);
  static const Color orange = Color(0xFFFF9500);
  static const Color red = Color(0xFFFF3B30);
  static const Color redAccent = Color(0xFFFF3B30);
  static const Color yellow = Color(0xFFFFD60A);
  static const Color blue = Color(0xFF007AFF);

  static const Gradient commonContainerGradient = LinearGradient(
    colors: [Color(0xFFD4A574), Color(0xFFB8956A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
