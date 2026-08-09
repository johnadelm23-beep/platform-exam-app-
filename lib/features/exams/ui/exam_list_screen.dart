import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';
import 'package:platformexamapp/core/widgets/empty_state.dart';
import 'package:platformexamapp/core/widgets/glass_card.dart';
import 'package:platformexamapp/core/widgets/loading_state.dart';
import 'package:platformexamapp/features/auth/data/models/user_data.dart';
import 'package:platformexamapp/features/exams/ui/exam_details_screen.dart';
import 'package:platformexamapp/core/widgets/app_dialog.dart';
import 'package:platformexamapp/core/theme/app_page_route.dart';

class ExamsScreen extends StatelessWidget {
  const ExamsScreen({super.key, required this.user});
  final UserData user;

  Future<void> deleteExam(String examId) async {
    await FirebaseFirestore.instance.collection("exams").doc(examId).delete();
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
                      "available_exams".tr(),
                      style: GoogleFonts.cairo(
                        fontSize: 24.sp,
                        color: textColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
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
                  stream: FirebaseFirestore.instance
                      .collection("exams")
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const LoadingState();
                    }
                    final exams = snapshot.data!.docs;
                    if (exams.isEmpty) {
                      return EmptyState(
                        title: "no_exams".tr(),
                        hugeIcon: HugeIcons.strokeRoundedFile01,
                      );
                    }
                    return ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      itemCount: exams.length,
                      separatorBuilder: (_, _) => SizedBox(height: 12.h),
                      itemBuilder: (context, index) {
                        final exam = exams[index];
                        return GlassCard(
                          onTap: () {
                            Navigator.push(
                              context,
                              AppPageRoute(
                                child: ExamDetailsScreen(
                                  examId: exam.id,
                                  title: exam["title"],
                                  time: exam["time"],
                                ),
                              ),
                            );
                          },
                          padding: EdgeInsets.all(16.r),
                          borderRadius: 20.r,
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(10.r),
                                decoration: BoxDecoration(
                                  color: AppColors.softGold.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: HugeIcon(
                                  icon: HugeIcons.strokeRoundedFile01,
                                  color: AppColors.softGold,
                                  size: 24.r,
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Text(
                                  exam["title"],
                                  style: GoogleFonts.cairo(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                              ),
                              if (user.isAdmin == true)
                                IconButton(
                                  icon: const HugeIcon(
                                    icon: HugeIcons.strokeRoundedDelete01,
                                    color: AppColors.heartRed,
                                  ),
                                  onPressed: () {
                                    AppDialog.show(
                                      context: context,
                                      iconWidget: Icon(
                                        Icons.delete_forever_rounded,
                                        color: AppColors.heartRed,
                                        size: 36.r,
                                      ),
                                      iconColor: AppColors.heartRed,
                                      title: "delete_exam".tr(),
                                      description: "delete_exam_desc".tr(),
                                      confirmText: "delete".tr(),
                                      confirmButtonColor: AppColors.heartRed,
                                      cancelText: "cancel".tr(),
                                      onConfirm: () async {
                                        Navigator.pop(context);
                                        await deleteExam(exam.id);
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              "exam_deleted_success".tr(),
                                              style: GoogleFonts.cairo(),
                                            ),
                                            backgroundColor:
                                                AppColors.successGreen,
                                          ),
                                        );
                                      },
                                      onCancel: () => Navigator.pop(context),
                                    );
                                  },
                                ),
                            ],
                          ),
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
