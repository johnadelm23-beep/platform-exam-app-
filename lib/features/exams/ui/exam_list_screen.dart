import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';
import 'package:platformexamapp/core/theme/app_page_route.dart';
import 'package:platformexamapp/core/widgets/app_dialog.dart';
import 'package:platformexamapp/core/widgets/empty_state.dart';
import 'package:platformexamapp/core/widgets/glass_card.dart';
import 'package:platformexamapp/core/widgets/loading_state.dart';
import 'package:platformexamapp/features/admin/ui/add_exam_screen.dart';
import 'package:platformexamapp/features/auth/data/models/user_data.dart';
import 'package:platformexamapp/features/exams/ui/exam_details_screen.dart';

class ExamsScreen extends StatefulWidget {
  const ExamsScreen({super.key, required this.user, this.isTab = false});
  final UserData user;
  final bool isTab;

  @override
  State<ExamsScreen> createState() => _ExamsScreenState();
}

class _ExamsScreenState extends State<ExamsScreen> {
  late final Stream<QuerySnapshot> _examsStream;
  late final Stream<QuerySnapshot> _attemptsStream;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? widget.user.uid;
    _examsStream = FirebaseFirestore.instance.collection("exams").snapshots();
    _attemptsStream = FirebaseFirestore.instance
        .collection("examAttempts")
        .where("userId", isEqualTo: uid)
        .snapshots();
  }

  Future<void> deleteExam(String examId) async {
    await FirebaseFirestore.instance.collection("exams").doc(examId).delete();
  }

  void showDeleteExamDialog(String examId) {
    AppDialog.show(
      context: context,
      iconWidget: HugeIcon(
        icon: HugeIcons.strokeRoundedDelete01,
        color: AppColors.heartRed,
        size: 36.r,
      ),
      iconColor: AppColors.heartRed,
      title: "delete_exam".tr(),
      description: "delete_exam_desc".tr(),
      confirmText: "delete".tr(),
      confirmButtonColor: AppColors.heartRed,
      cancelText: "cancel".tr(),
      onConfirm: () {
        Navigator.pop(context);
        deleteExam(examId);
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

    return Scaffold(
      backgroundColor: pageBg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(16.r),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "exams".tr(),
                      style: GoogleFonts.cairo(
                        fontSize: 22.sp,
                        color: textColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (!widget.isTab && Navigator.canPop(context))
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: EdgeInsets.all(10.r),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_back_ios,
                          color: textColor,
                          size: 18.r,
                        ),
                      ),
                    ),

                  if (widget.user.isAdmin == true) SizedBox(width: 8.w),

                  if (widget.user.isAdmin == true)
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          AppPageRoute(child: const AddExamScreen()),
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.all(10.r),
                        decoration: const BoxDecoration(
                          color: AppColors.softGold,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.add,
                          color: Colors.black87,
                          size: 18.r,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(32.r),
                  ),
                  border: Border(top: BorderSide(color: borderColor, width: 1)),
                ),
                child: StreamBuilder<QuerySnapshot>(
                  stream: _attemptsStream,
                  builder: (context, attemptsSnap) {
                    final Map<String, Map<String, dynamic>> userAttempts = {};
                    if (attemptsSnap.hasData) {
                      for (var doc in attemptsSnap.data!.docs) {
                        final d = doc.data() as Map<String, dynamic>;
                        final eid = (d["examId"] as String?) ?? "";
                        if (eid.isNotEmpty) {
                          userAttempts[eid] = d;
                        }
                      }
                    }

                    return StreamBuilder<QuerySnapshot>(
                      stream: _examsStream,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const LoadingState();
                        }
                        final rawExams = snapshot.data!.docs;
                        if (rawExams.isEmpty) {
                          return EmptyState(
                            title: "no_exams".tr(),
                            hugeIcon: HugeIcons.strokeRoundedFile01,
                          );
                        }

                        // Deterministic Sorting:
                        // 1. "order" field ascending (if explicitly defined)
                        // 2. "createdAt" timestamp descending (newer exams first)
                        // 3. Document ID ascending tiebreaker
                        final exams = rawExams.toList()
                          ..sort((a, b) {
                            final dataA = a.data() as Map<String, dynamic>;
                            final dataB = b.data() as Map<String, dynamic>;

                            final orderA = dataA["order"] as num?;
                            final orderB = dataB["order"] as num?;

                            if (orderA != null && orderB != null) {
                              final cmp = orderA.compareTo(orderB);
                              if (cmp != 0) return cmp;
                            } else if (orderA != null) {
                              return -1;
                            } else if (orderB != null) {
                              return 1;
                            }

                            final timeA = dataA["createdAt"] as Timestamp?;
                            final timeB = dataB["createdAt"] as Timestamp?;

                            if (timeA != null && timeB != null) {
                              final cmp = timeB.compareTo(timeA);
                              if (cmp != 0) return cmp;
                            } else if (timeA != null) {
                              return -1;
                            } else if (timeB != null) {
                              return 1;
                            }

                            final titleA = (dataA["title"] ?? "").toString();
                            final titleB = (dataB["title"] ?? "").toString();
                            return titleA.compareTo(titleB);
                          });

                        return ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.only(bottom: 80.h),
                          itemCount: exams.length,
                          separatorBuilder: (_, _) => SizedBox(height: 12.h),
                          itemBuilder: (context, index) {
                            final examDoc = exams[index];
                            return _ExamCardItem(
                              examDoc: examDoc,
                              isAdmin: widget.user.isAdmin == true,
                              attemptData: userAttempts[examDoc.id],
                              onDelete: () => showDeleteExamDialog(examDoc.id),
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

class _ExamCardItem extends StatelessWidget {
  final QueryDocumentSnapshot examDoc;
  final bool isAdmin;
  final Map<String, dynamic>? attemptData;
  final VoidCallback onDelete;

  const _ExamCardItem({
    required this.examDoc,
    required this.isAdmin,
    this.attemptData,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final data = examDoc.data() as Map<String, dynamic>;
    final title = (data["title"] ?? "").toString();
    final timeMinutes = (data["time"] as num?)?.toInt() ?? 0;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextMain : AppColors.lightTextMain;

    final isDone = attemptData?["done"] == true;
    final isAbandoned = attemptData?["abandoned"] == true;
    final status = (attemptData?["status"] as String?) ?? "";
    final score = (attemptData?["score"] as num?)?.toInt() ?? 0;

    final isTerminated = isAbandoned || status == "terminated";
    final isCompleted = isDone && !isAbandoned;

    return GlassCard(
      onTap: () {
        if (isTerminated) {
          AppDialog.show(
            context: context,
            iconWidget: Icon(
              Icons.block_rounded,
              color: AppColors.heartRed,
              size: 36.r,
            ),
            iconColor: AppColors.heartRed,
            title: "exam_terminated".tr(),
            description: "exam_already_terminated".tr(),
            confirmText: "ok".tr(),
            confirmButtonColor: AppColors.heartRed,
            onConfirm: () => Navigator.pop(context),
          );
          return;
        }

        if (isCompleted) {
          AppDialog.show(
            context: context,
            iconWidget: Icon(
              Icons.lock_rounded,
              color: AppColors.heartRed,
              size: 36.r,
            ),
            iconColor: AppColors.heartRed,
            title: "not_allowed".tr(),
            description: "exam_already_completed".tr(),
            confirmText: "ok".tr(),
            confirmButtonColor: AppColors.heartRed,
            onConfirm: () => Navigator.pop(context),
          );
          return;
        }

        Navigator.push(
          context,
          AppPageRoute(
            child: ExamDetailsScreen(
              examId: examDoc.id,
              title: title,
              time: timeMinutes,
            ),
          ),
        );
      },
      padding: EdgeInsets.all(16.r),
      borderRadius: 20.r,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: isTerminated
                      ? AppColors.heartRed.withValues(alpha: 0.15)
                      : isCompleted
                      ? AppColors.successGreen.withValues(alpha: 0.15)
                      : AppColors.softGold.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: HugeIcon(
                  icon: isTerminated
                      ? HugeIcons.strokeRoundedAlertCircle
                      : HugeIcons.strokeRoundedFile01,
                  color: isTerminated
                      ? AppColors.heartRed
                      : isCompleted
                      ? AppColors.successGreen
                      : AppColors.softGold,
                  size: 24.r,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isAdmin)
                IconButton(
                  onPressed: onDelete,
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedDelete01,
                    color: AppColors.softRed,
                  ),
                ),
            ],
          ),

          SizedBox(height: 12.h),

          /// Badges Row: Questions count, Duration, Status
          StreamBuilder<QuerySnapshot>(
            stream: examDoc.reference.collection("questions").snapshots(),
            builder: (context, qSnap) {
              final qCount = qSnap.hasData ? qSnap.data!.docs.length : null;
              final qText = qCount == null
                  ? "..."
                  : "exam_questions_count".tr(args: [qCount.toString()]);
              final timeText =
                  "exam_duration".tr(args: [timeMinutes.toString()]);

              return Wrap(
                spacing: 8.w,
                runSpacing: 6.h,
                children: [
                  /// Questions Badge
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedHelpCircle,
                          size: 14.r,
                          color: AppColors.softGold,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          qText,
                          style: GoogleFonts.cairo(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// Duration Badge
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: AppColors.softGold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: AppColors.softGold.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedClock01,
                          size: 14.r,
                          color: AppColors.softGold,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          timeText,
                          style: GoogleFonts.cairo(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.softGold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// Status Badge (Terminated or Completed)
                  if (isTerminated)
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: AppColors.heartRed.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: AppColors.heartRed.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.block_rounded,
                            size: 13.r,
                            color: AppColors.heartRed,
                          ),
                          SizedBox(width: 5.w),
                          Text(
                            "exam_status_terminated".tr(),
                            style: GoogleFonts.cairo(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.heartRed,
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (isCompleted)
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: AppColors.successGreen.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: AppColors.successGreen.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 13.r,
                            color: AppColors.successGreen,
                          ),
                          SizedBox(width: 5.w),
                          Text(
                            "${'exam_status_completed'.tr()} ($score)",
                            style: GoogleFonts.cairo(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.successGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
