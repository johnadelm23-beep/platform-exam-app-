import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';
import 'package:platformexamapp/core/widgets/glass_card.dart';
import 'package:platformexamapp/core/widgets/gold_button.dart';

class ExamDetailsBottomSheet extends StatelessWidget {
  final String examTitle;
  final int totalQuestions;
  final int correctAnswers;
  final int wrongAnswers;
  final double scorePercentage;
  final String timeTaken;
  final String examDate;
  final String gradeLabel;

  const ExamDetailsBottomSheet({
    super.key,
    required this.examTitle,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.scorePercentage,
    required this.timeTaken,
    required this.examDate,
    required this.gradeLabel,
  });

  static void show(
    BuildContext context, {
    required String examTitle,
    required int totalQuestions,
    required int correctAnswers,
    required int wrongAnswers,
    required double scorePercentage,
    required String timeTaken,
    required String examDate,
    required String gradeLabel,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExamDetailsBottomSheet(
        examTitle: examTitle,
        totalQuestions: totalQuestions,
        correctAnswers: correctAnswers,
        wrongAnswers: wrongAnswers,
        scorePercentage: scorePercentage,
        timeTaken: timeTaken,
        examDate: examDate,
        gradeLabel: gradeLabel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.darkSurface
        : AppColors.lightSurface;
    final textColor = isDark ? AppColors.darkTextMain : AppColors.lightTextMain;
    final mutedColor = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    Color gradeColor;
    if (scorePercentage >= 85) {
      gradeColor = AppColors.successGreen;
    } else if (scorePercentage >= 70) {
      gradeColor = AppColors.softGold;
    } else if (scorePercentage >= 50) {
      gradeColor = Colors.orange;
    } else {
      gradeColor = AppColors.heartRed;
    }

    return Container(
      padding: EdgeInsets.only(
        top: 16.r,
        left: 20.r,
        right: 20.r,
        bottom: MediaQuery.of(context).padding.bottom + 20.r,
      ),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28.r),
          topRight: Radius.circular(28.r),
        ),
        border: Border(top: BorderSide(color: borderColor, width: 1)),
        boxShadow: [
          BoxShadow(
            color: isDark ? const Color(0x66000000) : const Color(0x1A0F1C3F),
            blurRadius: 25,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: mutedColor.withOpacity(0.4),
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
          ),
          SizedBox(height: 16.h),

          // Header with Title and Grade
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "exam_details".tr(),
                      style: GoogleFonts.cairo(
                        fontSize: 12.sp,
                        color: mutedColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      examTitle,
                      style: GoogleFonts.cairo(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: gradeColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: gradeColor.withOpacity(0.3)),
                ),
                child: Text(
                  gradeLabel,
                  style: GoogleFonts.cairo(
                    color: gradeColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 20.h),
          Divider(color: borderColor, height: 1),
          SizedBox(height: 20.h),

          // Details Grid Metrics
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12.w,
            mainAxisSpacing: 12.h,
            childAspectRatio: 2.2,
            children: [
              _buildDetailItem(
                context,
                title: "total_questions".tr(),
                value: "$totalQuestions",
                icon: HugeIcons.strokeRoundedFile01,
                color: AppColors.softGold,
              ),
              _buildDetailItem(
                context,
                title: "correct_answers".tr(),
                value: "$correctAnswers",
                icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                color: AppColors.successGreen,
              ),
              _buildDetailItem(
                context,
                title: "wrong_answers".tr(),
                value: "$wrongAnswers",
                icon: HugeIcons.strokeRoundedCancel01,
                color: AppColors.heartRed,
              ),
              _buildDetailItem(
                context,
                title: "score_percentage".tr(),
                value: "${scorePercentage.toStringAsFixed(1)}%",
                icon: HugeIcons.strokeRoundedChart01,
                color: gradeColor,
              ),
              _buildDetailItem(
                context,
                title: "exam_duration".tr(),
                value: timeTaken,
                icon: HugeIcons.strokeRoundedClock01,
                color: Colors.purple.shade300,
              ),
              _buildDetailItem(
                context,
                title: "exam_date".tr(),
                value: examDate,
                icon: HugeIcons.strokeRoundedCalendar01,
                color: Colors.teal.shade300,
              ),
            ],
          ),

          SizedBox(height: 24.h),

          // Close button
          GoldButton(
            title: "close".tr(),
            onPressed: () => Navigator.pop(context),
            height: 48.h,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(
    BuildContext context, {
    required String title,
    required String value,
    required List<List<dynamic>> icon,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextMain : AppColors.lightTextMain;
    final mutedColor = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;

    return GlassCard(
      padding: EdgeInsets.all(10.r),
      borderRadius: 16.r,
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: HugeIcon(icon: icon, size: 16.r, color: color),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: GoogleFonts.cairo(fontSize: 11.sp, color: mutedColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  value,
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
          ),
        ],
      ),
    );
  }
}
