import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';
import 'package:platformexamapp/features/auth/data/models/user_data.dart';

class StudentProgressOverview extends StatelessWidget {
  final UserData user;
  final String uid;

  const StudentProgressOverview({
    super.key,
    required this.user,
    required this.uid,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextMain : AppColors.classicNavy;
    final mutedColor = isDark
        ? AppColors.darkTextMuted
        : AppColors.slate500;
    final cardBg = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.slate200;

    final attendanceRate = (user.attendancePercentage ?? 0.0).clamp(0.0, 100.0);
    final streak = user.displayStreak;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: AppColors.classicNavy.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(6.r),
                    decoration: BoxDecoration(
                      color: AppColors.accentTeal.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedAnalytics01,
                      size: 16.r,
                      color: AppColors.accentTeal,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    "student_progress".tr(),
                    style: GoogleFonts.cairo(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: AppColors.softGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "🔥 $streak",
                      style: GoogleFonts.cairo(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.goldDark,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      "streak".tr(),
                      style: GoogleFonts.cairo(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.goldDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // Horizontal Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: LinearProgressIndicator(
              value: attendanceRate / 100.0,
              minHeight: 7.h,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : AppColors.slate100,
              valueColor: AlwaysStoppedAnimation<Color>(
                attendanceRate >= 75
                    ? AppColors.accentTeal
                    : attendanceRate >= 50
                    ? AppColors.softGold
                    : AppColors.heartRed,
              ),
            ),
          ),
          SizedBox(height: 12.h),

          // 3 Metrics Columns
          Row(
            children: [
              // Metric 1: Attendance Rate
              Expanded(
                child: _buildMetricItem(
                  title: "attendance".tr(),
                  value: "${attendanceRate.toStringAsFixed(0)}%",
                  icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                  iconColor: AppColors.accentTeal,
                  textColor: textColor,
                  mutedColor: mutedColor,
                ),
              ),
              Container(
                height: 28.h,
                width: 1,
                color: isDark ? AppColors.darkBorder : AppColors.slate200,
              ),

              // Metric 2: Completed Exams
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("examAttempts")
                      .where("userId", isEqualTo: uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    int completedCount = 0;
                    if (snapshot.hasData) {
                      completedCount = snapshot.data!.docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return data["done"] == true && data["abandoned"] != true;
                      }).length;
                    }

                    return _buildMetricItem(
                      title: "my_exams".tr(),
                      value: "$completedCount",
                      icon: HugeIcons.strokeRoundedFile01,
                      iconColor: AppColors.classicNavy,
                      textColor: textColor,
                      mutedColor: mutedColor,
                    );
                  },
                ),
              ),
              Container(
                height: 28.h,
                width: 1,
                color: isDark ? AppColors.darkBorder : AppColors.slate200,
              ),

              // Metric 3: Total Attendances
              Expanded(
                child: _buildMetricItem(
                  title: "total_present".tr(),
                  value: "${user.totalAttendance ?? 0}",
                  icon: HugeIcons.strokeRoundedCalendar01,
                  iconColor: AppColors.softGold,
                  textColor: textColor,
                  mutedColor: mutedColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required String title,
    required String value,
    required dynamic icon,
    required Color iconColor,
    required Color textColor,
    required Color mutedColor,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HugeIcon(icon: icon, size: 14.r, color: iconColor),
            SizedBox(width: 4.w),
            Text(
              value,
              style: GoogleFonts.cairo(
                fontSize: 15.sp,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        Text(
          title,
          style: GoogleFonts.cairo(
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            color: mutedColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
