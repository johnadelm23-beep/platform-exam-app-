import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';
import 'package:platformexamapp/core/theme/app_page_route.dart';
import 'package:platformexamapp/features/auth/data/models/user_data.dart';
import 'package:platformexamapp/features/exams/ui/exam_details_screen.dart';
import 'package:platformexamapp/features/home/ui/daily_content_screen.dart';
import 'package:platformexamapp/features/profile/ui/profile_screen.dart';

class FeaturedHeroCard extends StatelessWidget {
  final UserData user;
  final String uid;

  const FeaturedHeroCard({
    super.key,
    required this.user,
    required this.uid,
  });

  @override
  Widget build(BuildContext context) {
    // 1. First priority: Check active event
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("events")
          .where("isActive", isEqualTo: true)
          .limit(1)
          .snapshots(),
      builder: (context, eventSnapshot) {
        if (eventSnapshot.hasData && eventSnapshot.data!.docs.isNotEmpty) {
          final eventDoc = eventSnapshot.data!.docs.first;
          final eventData = eventDoc.data() as Map<String, dynamic>;
          return _buildEventHeroCard(context, eventData);
        }

        // 2. Second priority: Check unattempted exams
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("exams")
              .orderBy("createdAt", descending: true)
              .limit(1)
              .snapshots(),
          builder: (context, examSnapshot) {
            if (examSnapshot.hasData && examSnapshot.data!.docs.isNotEmpty) {
              final examDoc = examSnapshot.data!.docs.first;
              final examData = examDoc.data() as Map<String, dynamic>;

              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("examAttempts")
                    .doc("${uid}_${examDoc.id}")
                    .snapshots(),
                builder: (context, attemptSnap) {
                  final attemptData = attemptSnap.data?.data() as Map<String, dynamic>?;
                  final isDone = attemptData?["done"] == true;

                  if (!isDone) {
                    return _buildExamHeroCard(context, examDoc.id, examData);
                  }

                  return _buildDailyLessonHeroCard(context);
                },
              );
            }

            return _buildDailyLessonHeroCard(context);
          },
        );
      },
    );
  }

  Widget _buildEventHeroCard(BuildContext context, Map<String, dynamic> data) {
    final title = (data["title"] ?? "Saint John Youth Meeting").toString();
    final desc = (data["description"] ?? "").toString();
    final dateStr = (data["date"] ?? "").toString();
    final timeStr = (data["time"] ?? "").toString();
    final type = (data["type"] ?? "friday_meeting").toString();

    String typeLabel = type == "friday_meeting"
        ? "friday_attendance".tr()
        : type == "sunday_activity"
        ? "sunday_attendance".tr()
        : "todays_meeting".tr();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.classicNavy,
            Color(0xFF0F1E36),
          ],
        ),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.classicNavy.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.accentTeal.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: AppColors.accentTeal.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6.r,
                      height: 6.r,
                      decoration: const BoxDecoration(
                        color: AppColors.accentTeal,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      typeLabel,
                      style: GoogleFonts.cairo(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accentTeal,
                      ),
                    ),
                  ],
                ),
              ),
              HugeIcon(
                icon: HugeIcons.strokeRoundedCalendar01,
                size: 20.r,
                color: Colors.white70,
              ),
            ],
          ),
          SizedBox(height: 12.h),

          Text(
            title,
            style: GoogleFonts.cairo(
              fontSize: 18.sp,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          if (desc.isNotEmpty) ...[
            SizedBox(height: 4.h),
            Text(
              desc,
              style: GoogleFonts.cairo(
                fontSize: 12.sp,
                color: Colors.white70,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          SizedBox(height: 14.h),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (dateStr.isNotEmpty) ...[
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedClock01,
                      size: 14.r,
                      color: AppColors.softGold,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      dateStr,
                      style: GoogleFonts.cairo(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 10.w),
                  ],
                  if (timeStr.isNotEmpty) ...[
                    Text(
                      timeStr,
                      style: GoogleFonts.cairo(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.softGold,
                      ),
                    ),
                  ],
                ],
              ),

              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    AppPageRoute(child: const ProfileScreen()),
                  );
                },
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedQrCode,
                  size: 14.r,
                  color: AppColors.classicNavy,
                ),
                label: Text(
                  "share_qr".tr(),
                  style: GoogleFonts.cairo(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.classicNavy,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.softGold,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExamHeroCard(BuildContext context, String examId, Map<String, dynamic> data) {
    final title = (data["title"] ?? "Exam").toString();
    final timeMinutes = (data["time"] as num?)?.toInt() ?? 0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.classicNavy,
            Color(0xFF132B45),
          ],
        ),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.classicNavy.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.softGold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: AppColors.softGold.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  "available_exams".tr(),
                  style: GoogleFonts.cairo(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.softGold,
                  ),
                ),
              ),
              HugeIcon(
                icon: HugeIcons.strokeRoundedFile01,
                size: 20.r,
                color: Colors.white70,
              ),
            ],
          ),
          SizedBox(height: 12.h),

          Text(
            title,
            style: GoogleFonts.cairo(
              fontSize: 18.sp,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          SizedBox(height: 14.h),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedClock01,
                    size: 14.r,
                    color: Colors.white70,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    "exam_duration".tr(args: [timeMinutes.toString()]),
                    style: GoogleFonts.cairo(
                      fontSize: 12.sp,
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    AppPageRoute(
                      child: ExamDetailsScreen(
                        examId: examId,
                        title: title,
                        time: timeMinutes,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentTeal,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ),
                child: Text(
                  "submit".tr(), // Or action button
                  style: GoogleFonts.cairo(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDailyLessonHeroCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.classicNavy,
            Color(0xFF1E355B),
          ],
        ),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.classicNavy.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  "Saint John Youth",
                  style: GoogleFonts.cairo(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.goldLight,
                  ),
                ),
              ),
              Image.asset(
                "assets/images/background.png",
                width: 28.w,
                height: 28.h,
              ),
            ],
          ),
          SizedBox(height: 12.h),

          Text(
            "todays_material".tr(),
            style: GoogleFonts.cairo(
              fontSize: 18.sp,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            "today_content_unlocked".tr(),
            style: GoogleFonts.cairo(
              fontSize: 12.sp,
              color: Colors.white70,
            ),
          ),

          SizedBox(height: 14.h),

          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  AppPageRoute(child: const DailyContentScreen()),
                );
              },
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedFileBookmark,
                size: 14.r,
                color: Colors.white,
              ),
              label: Text(
                "view_details".tr(),
                style: GoogleFonts.cairo(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentTeal,
                elevation: 0,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                minimumSize: Size.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
