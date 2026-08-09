import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';

class EmptyState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final List<List<dynamic>>? hugeIcon;

  const EmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.hugeIcon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextMain : AppColors.lightTextMain;
    final subtitleColor = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (hugeIcon != null)
              HugeIcon(
                icon: hugeIcon!,
                size: 56.r,
                color: AppColors.softGold.withValues(alpha: 0.7),
              )
            else
              Icon(
                icon ?? Icons.inbox_outlined,
                size: 56.r,
                color: AppColors.softGold.withValues(alpha: 0.7),
              ),
            SizedBox(height: 16.h),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            if (subtitle != null) ...[
              SizedBox(height: 6.h),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(fontSize: 13.sp, color: subtitleColor),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
