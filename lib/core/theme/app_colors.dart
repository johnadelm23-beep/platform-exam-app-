import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // --- BRAND COLORS ---
  static const Color deepNavy = Color(0xFF070E24);
  static const Color cinematicNavy = Color(0xFF0F1C3F);
  static const Color primaryLightNavy = Color(0xFF1E3A75);
  static const Color softGold = Color(0xFFD4AF37);
  static const Color goldLight = Color(0xFFF5D470);
  static const Color goldDark = Color(0xFFB3922E);

  // Backwards compatibility alias
  static const Color primaryColor = cinematicNavy;
  static const Color whiteColor = Colors.white;

  // --- DARK MODE TOKENS ---
  static const Color darkPageBg = Color(0xFF070E24);
  static const Color darkSurface = Color(0xFF0F1C3F);
  static const Color darkGlassSurface = Color(0x8C0F1C3F);
  static const Color darkUpdateSurface = Color(0x0AFFFFFF);
  static const Color darkWarmWhiteAlt = Color(0xE60F1C3F);
  static const Color darkLightGrayAlt = Color(0xE6070E24);
  static const Color darkTextMain = Color(0xFFF8FAFC);
  static const Color darkTextMuted = Color(0xFFCBD5E1); // Slate-300
  static const Color darkTextCaption = Color(0xFF94A3B8); // Slate-400
  static const Color darkTextInverse = Color(0xFF0F1C3F);
  static const Color darkBorder = Color(0x1FFFFFFF);
  static const Color darkNavbarBg = Color(0xF20F1C3F);

  // --- LIGHT MODE TOKENS ---
  static const Color lightPageBg = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightGlassSurface = Color(0xD9FFFFFF);
  static const Color lightUpdateSurface = Color(0xF2FFFFFF);
  static const Color lightTextMain = Color(0xFF0F1C3F);
  static const Color lightTextMuted = Color(0xFF475569); // Slate-600
  static const Color lightTextCaption = Color(0xFF64748B); // Slate-500
  static const Color lightBorder = Color(0x1A0F1C3F);

  // --- SYSTEM & UTILITY COLORS ---
  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD4AF37), Color(0xFFF5D470), Color(0xFFD4AF37)],
    stops: [0.0, 0.5, 1.0],
  );

  static const Color heartRed = Color(0xFFDC3545);
  static const Color softRed = Color(0xFFFF6B6B);
  static const Color successGreen = Color(0xFF25D366);
  static const Color facebookBlue = Color(0xFF1877F2);
  static const Color whatsappGreen = Color(0xFF25D366);
  static const Color tiktokPink = Color(0xFFFE2C55);
  static const Color instagramPink = Color(0xFFE1306C);
}
