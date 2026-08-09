import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:platformexamapp/core/widgets/app_dialog.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';
import 'package:platformexamapp/core/widgets/empty_state.dart';
import 'package:platformexamapp/core/widgets/glass_card.dart';
import 'package:platformexamapp/core/widgets/loading_state.dart';
import 'package:platformexamapp/features/auth/data/models/user_data.dart';

class ScoresStatisticsScreen extends StatelessWidget {
  const ScoresStatisticsScreen({super.key, this.user});
  final UserData? user;

  static final Map<String, String> examCache = {};

  Future<String> getUserName(String userId) async {
    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .get();

    return doc.data()?["name"] ?? "Unknown";
  }

  Future<String> getExamName(String examId) async {
    if (examCache.containsKey(examId)) return examCache[examId]!;

    final doc = await FirebaseFirestore.instance
        .collection("exams")
        .doc(examId)
        .get();

    final name = doc.data()?["title"] ?? "Unknown Exam";
    examCache[examId] = name;

    return name;
  }

  Future<void> deleteAttempt(BuildContext context, String docId) async {
    await FirebaseFirestore.instance
        .collection("examAttempts")
        .doc(docId)
        .delete();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Deleted successfully", style: GoogleFonts.cairo()),
          backgroundColor: AppColors.successGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void showDeleteDialog({
    required BuildContext context,
    required VoidCallback onDelete,
  }) {
    AppDialog.show(
      context: context,
      iconWidget: HugeIcon(
        icon: HugeIcons.strokeRoundedDelete01,
        color: AppColors.heartRed,
        size: 36.r,
      ),
      iconColor: AppColors.heartRed,
      title: "Delete Attempt",
      description: "Are you sure you want to delete this attempt?",
      confirmText: "Delete",
      confirmButtonColor: AppColors.heartRed,
      cancelText: "Cancel",
      onConfirm: () {
        Navigator.pop(context);
        onDelete();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageBg = isDark ? AppColors.darkPageBg : AppColors.lightPageBg;
    final textColor = isDark ? AppColors.darkTextMain : AppColors.lightTextMain;
    final surfaceColor = isDark
        ? AppColors.darkSurface
        : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final mutedColor = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;

    return Scaffold(
      backgroundColor: pageBg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(16.r),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: EdgeInsets.all(10.r),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.08)
                            : Colors.black.withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_back_ios,
                        color: textColor,
                        size: 18.r,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    "Top Grades 🏆",
                    style: GoogleFonts.cairo(
                      fontSize: 22.sp,
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32.r),
                    topRight: Radius.circular(32.r),
                  ),
                  border: Border(top: BorderSide(color: borderColor, width: 1)),
                ),
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("examAttempts")
                      .orderBy("score", descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          "Error loading data",
                          style: GoogleFonts.cairo(color: AppColors.heartRed),
                        ),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const LoadingState();
                    }

                    final attempts = snapshot.data!.docs;

                    if (attempts.isEmpty) {
                      return EmptyState(
                        title: "No Scores Recorded",
                        hugeIcon: HugeIcons.strokeRoundedAnalytics01,
                      );
                    }

                    return ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      itemCount: attempts.length,
                      separatorBuilder: (_, __) => SizedBox(height: 12.h),
                      itemBuilder: (context, index) {
                        final doc = attempts[index];
                        final data = doc.data() as Map<String, dynamic>;

                        final userId = data["userId"];
                        final examId = data["examId"];
                        final score = data["score"] ?? 0;

                        return FutureBuilder<String>(
                          future: getUserName(userId),
                          builder: (context, userSnap) {
                            final userName = userSnap.data ?? "Loading...";

                            return FutureBuilder<String>(
                              future: getExamName(examId),
                              builder: (context, examSnap) {
                                final examName = examSnap.data ?? "Loading...";

                                return GlassCard(
                                  padding: EdgeInsets.all(14.r),
                                  borderRadius: 18.r,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 42.r,
                                        height: 42.r,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppColors.softGold.withOpacity(
                                            0.15,
                                          ),
                                          border: Border.all(
                                            color: AppColors.softGold
                                                .withOpacity(0.4),
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            "${index + 1}",
                                            style: GoogleFonts.cairo(
                                              color: AppColors.softGold,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16.sp,
                                            ),
                                          ),
                                        ),
                                      ),

                                      SizedBox(width: 12.w),

                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              userName,
                                              style: GoogleFonts.cairo(
                                                fontSize: 15.sp,
                                                fontWeight: FontWeight.bold,
                                                color: textColor,
                                              ),
                                            ),
                                            SizedBox(height: 2.h),
                                            Text(
                                              examName,
                                              style: GoogleFonts.cairo(
                                                color: mutedColor,
                                                fontSize: 12.sp,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 10.w,
                                          vertical: 4.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.successGreen
                                              .withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(
                                            10.r,
                                          ),
                                          border: Border.all(
                                            color: AppColors.successGreen
                                                .withOpacity(0.3),
                                          ),
                                        ),
                                        child: Text(
                                          "$score pts",
                                          style: GoogleFonts.cairo(
                                            color: AppColors.successGreen,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12.sp,
                                          ),
                                        ),
                                      ),

                                      if (user?.isAdminVal == true) ...[
                                        SizedBox(width: 6.w),
                                        IconButton(
                                          icon: const HugeIcon(
                                            icon:
                                                HugeIcons.strokeRoundedDelete01,
                                            color: AppColors.heartRed,
                                          ),
                                          onPressed: () {
                                            showDeleteDialog(
                                              context: context,
                                              onDelete: () async {
                                                await deleteAttempt(
                                                  context,
                                                  doc.id,
                                                );
                                              },
                                            );
                                          },
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
