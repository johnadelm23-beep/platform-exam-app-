import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkPageBg,
      primaryColor: AppColors.cinematicNavy,
      cardColor: AppColors.darkSurface,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.softGold,
        secondary: AppColors.goldLight,
        surface: AppColors.darkSurface,
        background: AppColors.darkPageBg,
        error: AppColors.softRed,
        onPrimary: AppColors.darkTextInverse,
        onSecondary: AppColors.darkTextInverse,
        onSurface: AppColors.darkTextMain,
        onBackground: AppColors.darkTextMain,
        outline: AppColors.darkBorder,
      ),
      textTheme: GoogleFonts.cairoTextTheme(ThemeData.dark().textTheme)
          .copyWith(
            displayLarge: GoogleFonts.cairo(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: AppColors.darkTextMain,
            ),
            displayMedium: GoogleFonts.cairo(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: AppColors.darkTextMain,
            ),
            titleLarge: GoogleFonts.cairo(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.darkTextMain,
            ),
            titleMedium: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.darkTextMain,
            ),
            bodyLarge: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.darkTextMain,
            ),
            bodyMedium: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.darkTextMuted,
            ),
            labelLarge: GoogleFonts.cairo(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.darkTextMain,
            ),
            bodySmall: GoogleFonts.cairo(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.darkTextCaption,
            ),
          ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkNavbarBg,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.darkTextMain),
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppColors.darkTextMain,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkBorder,
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkGlassSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.softGold, width: 1.5),
        ),
        hintStyle: TextStyle(color: AppColors.darkTextCaption),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkNavbarBg,
        selectedItemColor: AppColors.softGold,
        unselectedItemColor: AppColors.darkTextCaption,
        type: BottomNavigationBarType.fixed,
        elevation: 10,
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightPageBg,
      primaryColor: AppColors.cinematicNavy,
      cardColor: AppColors.lightSurface,
      colorScheme: const ColorScheme.light(
        primary: AppColors.softGold,
        secondary: AppColors.goldDark,
        surface: AppColors.lightSurface,
        background: AppColors.lightPageBg,
        error: AppColors.heartRed,
        onPrimary: AppColors.cinematicNavy,
        onSecondary: Colors.white,
        onSurface: AppColors.lightTextMain,
        onBackground: AppColors.lightTextMain,
        outline: AppColors.lightBorder,
      ),
      textTheme: GoogleFonts.cairoTextTheme(ThemeData.light().textTheme)
          .copyWith(
            displayLarge: GoogleFonts.cairo(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: AppColors.lightTextMain,
            ),
            displayMedium: GoogleFonts.cairo(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: AppColors.lightTextMain,
            ),
            titleLarge: GoogleFonts.cairo(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.lightTextMain,
            ),
            titleMedium: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.lightTextMain,
            ),
            bodyLarge: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.lightTextMain,
            ),
            bodyMedium: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.lightTextMuted,
            ),
            labelLarge: GoogleFonts.cairo(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.lightTextMain,
            ),
            bodySmall: GoogleFonts.cairo(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.lightTextCaption,
            ),
          ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightSurface,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.lightTextMain),
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppColors.lightTextMain,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.lightBorder, width: 1),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.lightBorder, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.lightBorder,
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightGlassSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.softGold, width: 1.5),
        ),
        hintStyle: TextStyle(color: AppColors.lightTextCaption),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightSurface,
        selectedItemColor: AppColors.softGold,
        unselectedItemColor: AppColors.lightTextCaption,
        type: BottomNavigationBarType.fixed,
        elevation: 10,
      ),
    );
  }
}
