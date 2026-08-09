import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';

class CustomTextRich extends StatelessWidget {
  const CustomTextRich({super.key, required this.text1, required this.text2});
  final String text1;
  final String text2;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: "$text1 ",
            style: GoogleFonts.cairo(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: primaryTextColor,
            ),
          ),
          TextSpan(
            text: text2,
            style: GoogleFonts.cairo(
              fontSize: 14.sp,
              color: AppColors.softGold,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
