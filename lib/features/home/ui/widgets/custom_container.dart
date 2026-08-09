import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';
import 'package:platformexamapp/core/widgets/glass_card.dart';

class CustomContainer extends StatelessWidget {
  final String title;
  final dynamic icon;
  final Color color;
  final Function()? onTap;

  const CustomContainer({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextMain : AppColors.lightTextMain;

    return GlassCard(
      onTap: onTap,
      padding: EdgeInsets.all(12.r),
      borderRadius: 20.r,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: icon is IconData
                ? Icon(icon as IconData, size: 28.r, color: color)
                : icon is List<List<dynamic>>
                ? HugeIcon(
                    icon: icon as List<List<dynamic>>,
                    size: 28.r,
                    color: color,
                  )
                : Icon(Icons.star, size: 28.r, color: color),
          ),
          SizedBox(height: 8.h),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
