import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';

class AppDimensions {
  AppDimensions._();

  static double radiusSm = 12.r;
  static double radiusMd = 16.r;
  static double radiusLg = 24.r;
  static double radiusXl = 30.r;

  static const BoxShadow shadowSm = BoxShadow(
    color: Color(0x4D000000),
    blurRadius: 6,
    offset: Offset(0, 4),
  );

  static const BoxShadow shadowMd = BoxShadow(
    color: Color(0x66000000),
    blurRadius: 30,
    offset: Offset(0, 10),
  );

  static const BoxShadow shadowLg = BoxShadow(
    color: Color(0x99000000),
    blurRadius: 50,
    offset: Offset(0, 20),
  );

  static const BoxShadow shadowGold = BoxShadow(
    color: Color(0x4DD4AF37),
    blurRadius: 40,
    offset: Offset(0, 10),
  );

  static const BoxShadow shadowGlow = BoxShadow(
    color: Color(0x80D4AF37),
    blurRadius: 30,
    offset: Offset(0, 0),
  );

  static BoxShadow lightCardShadow = BoxShadow(
    color: AppColors.cinematicNavy.withOpacity(0.08),
    blurRadius: 20,
    offset: const Offset(0, 8),
  );
}
