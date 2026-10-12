import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';
import 'package:platformexamapp/features/profile/ui/widgets/exam_details_bottom_sheet.dart';

class ExamDetailsData {
  final String title;
  final int time;
  final int totalQuestions;

  ExamDetailsData({
    required this.title,
    required this.time,
    required this.totalQuestions,
  });
}

class CustomBodyContainer extends StatelessWidget {
  final String uid;

  const CustomBodyContainer({super.key, this.uid = ""});

  static final Map<String, ExamDetailsData> _examCache = {};

  Future<ExamDetailsData> _getExamDetails(String examId) async {
    if (examId.isEmpty) {
      return ExamDetailsData(title: "Exam", time: 0, totalQuestions: 0);
    }
    if (_examCache.containsKey(examId)) return _examCache[examId]!;

    try {
      final doc = await FirebaseFirestore.instance
          .collection("exams")
          .doc(examId)
          .get();
      final title = (doc.data()?["title"] as String?) ?? "Exam";
      final time = (doc.data()?["time"] ?? 0) as int;

      final qSnap = await FirebaseFirestore.instance
          .collection("exams")
          .doc(examId)
          .collection("questions")
          .get();
      final totalQuestions = qSnap.docs.length;

      final details = ExamDetailsData(
        title: title,
        time: time,
        totalQuestions: totalQuestions,
      );
      _examCache[examId] = details;
      return details;
    } catch (e) {
      debugPrint("Error fetching exam details for $examId: $e");
      return ExamDetailsData(title: "Exam", time: 0, totalQuestions: 0);
    }
  }

  Future<List<Map<String, dynamic>>> _loadExamDetailsForAttempts(
    BuildContext context,
    List<QueryDocumentSnapshot> docs,
  ) async {
    List<Map<String, dynamic>> results = [];

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final examId = data["examId"] as String? ?? "";
      final score = (data["score"] ?? 0) as int;
      final timestamp = data["timestamp"];

      final details = await _getExamDetails(examId);

      final totalQuestions = details.totalQuestions > 0
          ? details.totalQuestions
          : (score > 0 ? score : 1);
      final scorePercentage = (score / totalQuestions) * 100.0;
      final wrongAnswers = (totalQuestions - score).clamp(0, 9999);

      String gradeLabel;
      Color gradeColor;
      if (scorePercentage >= 85) {
        gradeLabel = "grade_excellent".tr();
        gradeColor = AppColors.successGreen;
      } else if (scorePercentage >= 70) {
        gradeLabel = "grade_very_good".tr();
        gradeColor = Colors.blue;
      } else if (scorePercentage >= 50) {
        gradeLabel = "grade_good".tr();
        gradeColor = Colors.amber.shade800;
      } else {
        gradeLabel = "grade_needs_improvement".tr();
        gradeColor = AppColors.heartRed;
      }

      String submissionDate = "";
      if (timestamp != null && timestamp is Timestamp) {
        final dt = timestamp.toDate();
        submissionDate = DateFormat('yyyy-MM-dd').format(dt);
      }

      results.add({
        "examId": examId,
        "title": details.title,
        "score": score,
        "totalQuestions": totalQuestions,
        "scorePercentage": scorePercentage,
        "wrongAnswers": wrongAnswers,
        "gradeLabel": gradeLabel,
        "gradeColor": gradeColor,
        "submissionDate": submissionDate,
        "timeTaken": "${details.time}m",
      });
    }

    return results;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.slate200;
    final textColor = isDark ? AppColors.darkTextMain : AppColors.classicNavy;
    final subtitleColor = isDark ? AppColors.darkTextMuted : AppColors.slate500;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("examAttempts")
          .where("userId", isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: CircularProgressIndicator(color: AppColors.softGold),
            ),
          );
        }

        if (snapshot.hasError) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text(
                "error".tr(),
                style: GoogleFonts.cairo(color: AppColors.heartRed),
              ),
            ),
          );
        }

        final docs = (snapshot.data?.docs ?? []).where((d) {
          final m = d.data() as Map<String, dynamic>;
          return m["done"] == true && m["abandoned"] != true;
        }).toList();

        if (docs.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: _buildEmptyState(isDark, textColor, subtitleColor),
          );
        }

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _loadExamDetailsForAttempts(context, docs),
          builder: (context, detailsSnapshot) {
            if (detailsSnapshot.connectionState == ConnectionState.waiting) {
              return const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.softGold),
                ),
              );
            }

            final items = detailsSnapshot.data ?? [];

            // Stats calculation
            final completedCount = items.length;
            double avgScore = 0.0;
            double highestScore = 0.0;
            if (completedCount > 0) {
              final totalPct = items.fold<double>(
                0.0,
                (sum, e) => sum + (e["scorePercentage"] as double),
              );
              avgScore = totalPct / completedCount;
              highestScore = items.fold<double>(
                0.0,
                (max, e) =>
                    (e["scorePercentage"] as double) > max
                        ? (e["scorePercentage"] as double)
                        : max,
              );
            }

            return MultiSliverWrapper(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 16.h,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Summary Cards
                        Row(
                          children: [
                            Expanded(
                              child: _buildSummaryMetricCard(
                                title: "completed_exams".tr(),
                                value: "$completedCount",
                                icon: HugeIcons.strokeRoundedFile01,
                                color: AppColors.accentTeal,
                                cardBg: cardBg,
                                borderColor: borderColor,
                                subtitleColor: subtitleColor,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: _buildSummaryMetricCard(
                                title: "average_score".tr(),
                                value: "${avgScore.toStringAsFixed(1)}%",
                                icon: HugeIcons.strokeRoundedChart01,
                                color: Colors.blue,
                                cardBg: cardBg,
                                borderColor: borderColor,
                                subtitleColor: subtitleColor,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: _buildSummaryMetricCard(
                                title: "highest_score".tr(),
                                value: "${highestScore.toStringAsFixed(1)}%",
                                icon: HugeIcons.strokeRoundedAward01,
                                color: Colors.amber.shade800,
                                cardBg: cardBg,
                                borderColor: borderColor,
                                subtitleColor: subtitleColor,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20.h),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "my_exams".tr(),
                              style: GoogleFonts.cairo(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accentTeal.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Text(
                                "$completedCount",
                                style: GoogleFonts.cairo(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.accentTeal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // List of exam cards
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: 12.h),
                          child: _buildExamCard(
                            context,
                            items[index],
                            isDark,
                            cardBg,
                            borderColor,
                            textColor,
                            subtitleColor,
                          ),
                        );
                      },
                      childCount: items.length,
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: SizedBox(height: 30.h)),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSummaryMetricCard({
    required String title,
    required String value,
    required dynamic icon,
    required Color color,
    required Color cardBg,
    required Color borderColor,
    required Color subtitleColor,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 8.w),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          HugeIcon(icon: icon, size: 18.r, color: color),
          SizedBox(height: 6.h),
          Text(
            title,
            style: GoogleFonts.cairo(
              fontSize: 10.sp,
              color: subtitleColor,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: GoogleFonts.cairo(
              fontSize: 15.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamCard(
    BuildContext context,
    Map<String, dynamic> item,
    bool isDark,
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color subtitleColor,
  ) {
    final Color gradeColor = item["gradeColor"] as Color;
    final String gradeLabel = item["gradeLabel"] as String;
    final double scorePct = item["scorePercentage"] as double;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: borderColor),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item["title"] as String,
                    style: GoogleFonts.cairo(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 8.w),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: gradeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    gradeLabel,
                    style: GoogleFonts.cairo(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: gradeColor,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),

            Row(
              children: [
                _buildInfoBadge(
                  icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                  label: "${item["score"]}/${item["totalQuestions"]}",
                  color: AppColors.successGreen,
                  subtitleColor: subtitleColor,
                ),
                SizedBox(width: 12.w),
                _buildInfoBadge(
                  icon: HugeIcons.strokeRoundedClock01,
                  label: item["timeTaken"] as String,
                  color: Colors.blue,
                  subtitleColor: subtitleColor,
                ),
                if ((item["submissionDate"] as String).isNotEmpty) ...[
                  SizedBox(width: 12.w),
                  _buildInfoBadge(
                    icon: HugeIcons.strokeRoundedCalendar01,
                    label: item["submissionDate"] as String,
                    color: Colors.amber.shade800,
                    subtitleColor: subtitleColor,
                  ),
                ],
              ],
            ),
            SizedBox(height: 14.h),

            ClipRRect(
              borderRadius: BorderRadius.circular(6.r),
              child: LinearProgressIndicator(
                value: (scorePct / 100.0).clamp(0.0, 1.0),
                backgroundColor: gradeColor.withValues(alpha: 0.1),
                color: gradeColor,
                minHeight: 8.h,
              ),
            ),
            SizedBox(height: 14.h),

            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: ElevatedButton.icon(
                onPressed: () {
                  ExamDetailsBottomSheet.show(
                    context,
                    examTitle: item["title"] as String,
                    totalQuestions: item["totalQuestions"] as int,
                    correctAnswers: item["score"] as int,
                    wrongAnswers: item["wrongAnswers"] as int,
                    scorePercentage: scorePct,
                    timeTaken: item["timeTaken"] as String,
                    examDate: item["submissionDate"] as String,
                    gradeLabel: gradeLabel,
                  );
                },
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedView,
                  size: 14.r,
                  color: isDark ? AppColors.accentTeal : AppColors.classicNavy,
                ),
                label: Text(
                  "view_details".tr(),
                  style: GoogleFonts.cairo(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.accentTeal : AppColors.classicNavy,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: (isDark
                          ? AppColors.accentTeal
                          : AppColors.classicNavy)
                      .withValues(alpha: 0.1),
                  elevation: 0,
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 8.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBadge({
    required dynamic icon,
    required String label,
    required Color color,
    required Color subtitleColor,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        HugeIcon(icon: icon, size: 14.r, color: color),
        SizedBox(width: 4.w),
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: subtitleColor,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isDark, Color textColor, Color subtitleColor) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 40.h, horizontal: 20.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(
                color: AppColors.accentTeal.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Text("📚", style: TextStyle(fontSize: 44.sp)),
            ),
            SizedBox(height: 16.h),
            Text(
              "no_completed_exams".tr(),
              style: GoogleFonts.cairo(
                fontSize: 17.sp,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 6.h),
            Text(
              "take_exam_hint".tr(),
              style: GoogleFonts.cairo(fontSize: 13.sp, color: subtitleColor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class MultiSliverWrapper extends StatelessWidget {
  final List<Widget> slivers;
  const MultiSliverWrapper({super.key, required this.slivers});

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(slivers: slivers);
  }
}
