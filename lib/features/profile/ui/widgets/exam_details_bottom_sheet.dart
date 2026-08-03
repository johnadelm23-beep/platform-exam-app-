import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';

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
    Color gradeColor;
    if (scorePercentage >= 85) {
      gradeColor = Colors.green;
    } else if (scorePercentage >= 70) {
      gradeColor = Colors.blue;
    } else if (scorePercentage >= 50) {
      gradeColor = Colors.orange;
    } else {
      gradeColor = Colors.red;
    }

    return Container(
      padding: EdgeInsets.only(
        top: 16.r,
        left: 20.r,
        right: 20.r,
        bottom: MediaQuery.of(context).padding.bottom + 20.r,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28.r),
          topRight: Radius.circular(28.r),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
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
                color: Colors.grey[300],
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
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      examTitle,
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: gradeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: gradeColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  gradeLabel,
                  style: TextStyle(
                    color: gradeColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 20.h),
          Divider(color: Colors.grey[200], height: 1),
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
                title: "total_questions".tr(),
                value: "$totalQuestions",
                icon: HugeIcons.strokeRoundedFile01,
                color: AppColors.primaryColor,
              ),
              _buildDetailItem(
                title: "correct_answers".tr(),
                value: "$correctAnswers",
                icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                color: Colors.green,
              ),
              _buildDetailItem(
                title: "wrong_answers".tr(),
                value: "$wrongAnswers",
                icon: HugeIcons.strokeRoundedCancel01,
                color: Colors.red,
              ),
              _buildDetailItem(
                title: "score_percentage".tr(),
                value: "${scorePercentage.toStringAsFixed(1)}%",
                icon: HugeIcons.strokeRoundedChart01,
                color: gradeColor,
              ),
              _buildDetailItem(
                title: "exam_duration".tr(),
                value: timeTaken,
                icon: HugeIcons.strokeRoundedClock01,
                color: Colors.purple,
              ),
              _buildDetailItem(
                title: "exam_date".tr(),
                value: examDate,
                icon: HugeIcons.strokeRoundedCalendar01,
                color: Colors.teal,
              ),
            ],
          ),

          SizedBox(height: 24.h),

          // Close button
          SizedBox(
            width: double.infinity,
            height: 48.h,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
                elevation: 0,
              ),
              child: Text(
                "close".tr(),
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required String title,
    required String value,
    required List<List<dynamic>> icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(10.r),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18.r,
            backgroundColor: color.withValues(alpha: 0.15),
            child: HugeIcon(icon: icon, size: 18.r, color: color),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
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
