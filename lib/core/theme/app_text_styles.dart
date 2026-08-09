import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle displayLarge(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GoogleFonts.cairo(
      fontSize: 36.sp,
      fontWeight: FontWeight.w900,
      height: 1.2,
      letterSpacing: -0.5,
      color: isDark ? AppColors.darkTextMain : AppColors.lightTextMain,
    );
  }

  static TextStyle displayMedium(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GoogleFonts.cairo(
      fontSize: 28.sp,
      fontWeight: FontWeight.w900,
      height: 1.3,
      letterSpacing: -0.5,
      color: isDark ? AppColors.darkTextMain : AppColors.lightTextMain,
    );
  }

  static TextStyle titleLarge(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GoogleFonts.cairo(
      fontSize: 20.sp,
      fontWeight: FontWeight.w800,
      height: 1.4,
      color: isDark ? AppColors.darkTextMain : AppColors.lightTextMain,
    );
  }

  static TextStyle titleMedium(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GoogleFonts.cairo(
      fontSize: 16.sp,
      fontWeight: FontWeight.w700,
      height: 1.4,
      color: isDark ? AppColors.darkTextMain : AppColors.lightTextMain,
    );
  }

  static TextStyle bodyLarge(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GoogleFonts.cairo(
      fontSize: 16.sp,
      fontWeight: FontWeight.w600,
      height: 1.7,
      color: isDark ? AppColors.darkTextMain : AppColors.lightTextMain,
    );
  }

  static TextStyle bodyMedium(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GoogleFonts.cairo(
      fontSize: 14.sp,
      fontWeight: FontWeight.w400,
      height: 1.7,
      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
    );
  }

  static TextStyle labelLarge(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GoogleFonts.cairo(
      fontSize: 15.sp,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
      color: isDark ? AppColors.darkTextMain : AppColors.lightTextMain,
    );
  }

  static TextStyle caption(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GoogleFonts.cairo(
      fontSize: 12.sp,
      fontWeight: FontWeight.w600,
      height: 1.4,
      color: isDark ? AppColors.darkTextCaption : AppColors.lightTextCaption,
    );
  }
}
