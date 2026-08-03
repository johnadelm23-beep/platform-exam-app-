import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
      return ExamDetailsData(
        title: "Exam",
        time: 0,
        totalQuestions: 0,
      );
    }
  }

  Future<List<Map<String, dynamic>>> _loadExamDetailsForAttempts(
    BuildContext context,
    List<QueryDocumentSnapshot> docs,
  ) async {
    List<Map<String, dynamic>> results = [];
    final isArabic = EasyLocalization.of(context)?.locale.languageCode == 'ar';

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final examId = data["examId"] as String? ?? "";
      final score = (data["score"] ?? 0) as int;
      final timestamp = data["timestamp"];

      final details = await _getExamDetails(examId);

      final totalQuestions = details.totalQuestions > 0 ? details.totalQuestions : (score > 0 ? score : 1);
      final scorePercentage = (score / totalQuestions) * 100.0;
      final wrongAnswers = (totalQuestions - score).clamp(0, 9999);

      debugPrint("Exam ID found: $examId");
      debugPrint("Exam Title: ${details.title}");
      debugPrint("Question Count: $totalQuestions");
      debugPrint("Score: $score");
      debugPrint("Calculated Percentage: ${scorePercentage.toStringAsFixed(1)}%");

      String gradeLabel;
      Color gradeColor;
      if (scorePercentage >= 85) {
        gradeLabel = isArabic ? "ممتاز" : "Excellent";
        gradeColor = Colors.green;
      } else if (scorePercentage >= 70) {
        gradeLabel = isArabic ? "جيد جداً" : "Very Good";
        gradeColor = Colors.blue;
      } else if (scorePercentage >= 50) {
        gradeLabel = isArabic ? "جيد" : "Pass";
        gradeColor = Colors.orange;
      } else {
        gradeLabel = isArabic ? "راسب" : "Fail";
        gradeColor = Colors.red;
      }

      String submissionDate = "N/A";
      if (timestamp is Timestamp) {
        final dt = timestamp.toDate();
        submissionDate =
            "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
      }

      results.add({
        "attemptDoc": doc,
        "examId": examId,
        "title": details.title,
        "time": details.time,
        "totalQuestions": totalQuestions,
        "score": score,
        "wrongAnswers": wrongAnswers,
        "scorePercentage": scorePercentage,
        "gradeLabel": gradeLabel,
        "gradeColor": gradeColor,
        "submissionDate": submissionDate,
        "timeTaken": "${details.time} min",
      });
    }
    return results;
  }

  @override
  Widget build(BuildContext context) {
    final effectiveUid = uid.isNotEmpty ? uid : (FirebaseAuth.instance.currentUser?.uid ?? "");
    final isArabic = EasyLocalization.of(context)?.locale.languageCode == 'ar';

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("examAttempts")
          .where("userId", isEqualTo: effectiveUid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryColor),
          );
        }

        final allDocs = snapshot.data?.docs ?? [];
        final completedDocs = allDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final done = data["done"] == true;
          final abandoned = data["abandoned"] == true;
          final hasScore = data.containsKey("score") && data["score"] != null;
          return !abandoned && (done || hasScore);
        }).toList();

        debugPrint("=== EXAM RESULTS DEBUG LOGS ===");
        debugPrint("Current User UID: $effectiveUid");
        debugPrint("Number of examAttempts: ${allDocs.length}");
        debugPrint("Number of completed examAttempts: ${completedDocs.length}");

        if (completedDocs.isEmpty) {
          return _buildEmptyState(context);
        }

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _loadExamDetailsForAttempts(context, completedDocs),
          builder: (context, detailsSnap) {
            if (detailsSnap.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primaryColor),
              );
            }

            final items = detailsSnap.data ?? [];
            if (items.isEmpty) {
              return _buildEmptyState(context);
            }

            final completedCount = items.length;
            final double totalPct = items.fold(0.0, (total, i) => total + (i["scorePercentage"] as double));
            final double avgScore = completedCount > 0 ? (totalPct / completedCount) : 0.0;
            final double highestScore = items.fold(0.0, (max, i) {
              final pct = i["scorePercentage"] as double;
              return pct > max ? pct : max;
            });

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Summary Cards
                        Row(
                          children: [
                            Expanded(
                              child: _buildSummaryMetricCard(
                                title: isArabic ? "الامتحانات المكتملة" : "Completed Exams",
                                value: "$completedCount",
                                icon: HugeIcons.strokeRoundedFile01,
                                color: AppColors.primaryColor,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: _buildSummaryMetricCard(
                                title: isArabic ? "متوسط الدرجات" : "Average Score",
                                value: "${avgScore.toStringAsFixed(1)}%",
                                icon: HugeIcons.strokeRoundedChart01,
                                color: Colors.blue,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: _buildSummaryMetricCard(
                                title: isArabic ? "أعلى درجة" : "Highest Score",
                                value: "${highestScore.toStringAsFixed(1)}%",
                                icon: HugeIcons.strokeRoundedAward01,
                                color: Colors.amber[800]!,
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
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Text(
                                "$completedCount",
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                      ],
                    ),
                  ),
                ),

                // Completed Exam Cards List
                SliverPadding(
                  padding: EdgeInsets.only(
                    left: 16.w,
                    right: 16.w,
                    bottom: 24.h,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = items[index];
                        return Padding(
                          padding: EdgeInsets.only(bottom: 12.h),
                          child: _buildExamCard(context, item, isArabic),
                        );
                      },
                      childCount: items.length,
                    ),
                  ),
                ),
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
    required List<List<dynamic>> icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 8.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          HugeIcon(icon: icon, size: 18.r, color: color),
          SizedBox(height: 6.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 10.sp,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamCard(BuildContext context, Map<String, dynamic> item, bool isArabic) {
    final Color gradeColor = item["gradeColor"] as Color;
    final String gradeLabel = item["gradeLabel"] as String;
    final double scorePct = item["scorePercentage"] as double;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + Grade Badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    item["title"] as String,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 8.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: gradeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: gradeColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    gradeLabel,
                    style: TextStyle(
                      color: gradeColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.sp,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),

            // Date & Score %
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedCalendar01,
                      size: 13.r,
                      color: Colors.grey[500]!,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      item["submissionDate"] as String,
                      style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                    ),
                  ],
                ),
                Text(
                  "${scorePct.toStringAsFixed(1)}%",
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: gradeColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),

            // Progress Indicator
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

            // View Details Button
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
                  color: AppColors.primaryColor,
                ),
                label: Text(
                  isArabic ? "عرض التفاصيل" : "View Details",
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor.withValues(alpha: 0.08),
                  foregroundColor: AppColors.primaryColor,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
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

  Widget _buildEmptyState(BuildContext context) {
    final isArabic = EasyLocalization.of(context)?.locale.languageCode == 'ar';
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Text(
                "📚",
                style: TextStyle(fontSize: 48.sp),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              isArabic ? "لا توجد امتحانات مكتملة بعد." : "No completed exams yet.",
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              isArabic
                  ? "خوض امتحاناً لرؤية نتائجك هنا."
                  : "Take an exam to see your results here.",
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
