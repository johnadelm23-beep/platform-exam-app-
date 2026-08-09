import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';
import 'package:platformexamapp/core/widgets/glass_card.dart';
import 'package:platformexamapp/features/profile/ui/widgets/exam_details_bottom_sheet.dart';

class ExamCard extends StatelessWidget {
  final String examTitle;
  final double scorePercentage;
  final String grade;
  final String date;
  final String status;
  final int totalQuestions;
  final int correctAnswers;
  final int wrongAnswers;
  final String timeTaken;

  const ExamCard({
    super.key,
    required this.examTitle,
    required this.scorePercentage,
    required this.grade,
    required this.date,
    required this.status,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.timeTaken,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextMain : AppColors.lightTextMain;
    final mutedColor = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;

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

    return GlassCard(
      padding: EdgeInsets.all(16.r),
      borderRadius: 20.r,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Icon + Title + Score % Tag
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: AppColors.softGold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedFile01,
                  size: 22.r,
                  color: AppColors.softGold,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      examTitle,
                      style: GoogleFonts.cairo(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedCalendar01,
                          size: 13.r,
                          color: mutedColor,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          date,
                          style: GoogleFonts.cairo(
                            fontSize: 12.sp,
                            color: mutedColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: gradeColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: gradeColor.withOpacity(0.3)),
                ),
                child: Text(
                  "${scorePercentage.toStringAsFixed(0)}%",
                  style: GoogleFonts.cairo(
                    color: gradeColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 15.sp,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 12.h),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: LinearProgressIndicator(
              value: (scorePercentage / 100).clamp(0.0, 1.0),
              minHeight: 8.h,
              backgroundColor: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.05),
              valueColor: AlwaysStoppedAnimation<Color>(gradeColor),
            ),
          ),

          SizedBox(height: 12.h),

          // Grade, Status & View Details Button Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: gradeColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: gradeColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      grade,
                      style: GoogleFonts.cairo(
                        fontSize: 11.sp,
                        color: gradeColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkGlassSurface
                          : AppColors.lightGlassSurface,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                      ),
                    ),
                    child: Text(
                      status,
                      style: GoogleFonts.cairo(
                        fontSize: 11.sp,
                        color: mutedColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: () {
                  ExamDetailsBottomSheet.show(
                    context,
                    examTitle: examTitle,
                    totalQuestions: totalQuestions,
                    correctAnswers: correctAnswers,
                    wrongAnswers: wrongAnswers,
                    scorePercentage: scorePercentage,
                    timeTaken: timeTaken,
                    examDate: date,
                    gradeLabel: grade,
                  );
                },
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedEye,
                  size: 14.r,
                  color: AppColors.softGold,
                ),
                label: Text(
                  "view_details".tr(),
                  style: GoogleFonts.cairo(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.softGold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 6.h,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  side: const BorderSide(color: AppColors.softGold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
