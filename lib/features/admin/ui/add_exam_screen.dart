import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';
import 'package:platformexamapp/core/widgets/app_button.dart';
import 'package:platformexamapp/core/widgets/custom_text_form_field.dart';
import 'package:platformexamapp/core/widgets/glass_card.dart';
import 'package:platformexamapp/features/admin/ui/add_question_screen.dart';
import 'package:platformexamapp/core/theme/app_page_route.dart';

class AddExamScreen extends StatefulWidget {
  const AddExamScreen({super.key});

  @override
  State<AddExamScreen> createState() => _AddExamScreenState();
}

class _AddExamScreenState extends State<AddExamScreen> {
  final titleController = TextEditingController();
  final timeController = TextEditingController();

  bool isLoading = false;

  bool validate() {
    final title = titleController.text.trim();
    final time = timeController.text.trim();

    if (title.isEmpty) {
      _showError("Exam title can't be empty");
      return false;
    }

    if (time.isEmpty) {
      _showError("Time can't be empty");
      return false;
    }

    final parsed = int.tryParse(time);
    if (parsed == null || parsed <= 0) {
      _showError("Enter valid time in minutes");
      return false;
    }

    return true;
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.cairo()),
        backgroundColor: AppColors.heartRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void createExam() {
    if (!validate()) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    Navigator.push(
      context,
      AppPageRoute(
        child: AddQuestionScreen(
          examTitle: titleController.text.trim(),
          examTime: int.parse(timeController.text.trim()),
        ),
      ),
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
                    "create_exam".tr(),
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
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(height: 10.h),
                      GlassCard(
                        padding: EdgeInsets.all(20.r),
                        borderRadius: 24.r,
                        child: Column(
                          children: [
                            Image.asset(
                              "assets/images/background.png",
                              height: 110.h,
                            ),
                            SizedBox(height: 12.h),
                            Text(
                              "create_your_exam".tr(),
                              style: GoogleFonts.cairo(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              "add_title_and_duration".tr(),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.cairo(
                                color: mutedColor,
                                fontSize: 13.sp,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 20.h),

                      CustomTextFormField(
                        hintText: "exam_title".tr(),
                        controller: titleController,
                      ),

                      SizedBox(height: 12.h),

                      CustomTextFormField(
                        hintText: "Time".tr(),
                        controller: timeController,
                        keyboardType: TextInputType.number,
                      ),

                      SizedBox(height: 28.h),

                      AppButton(
                        onPressed: isLoading ? null : createExam,
                        text: isLoading ? "Creating..." : "Next_add_Q".tr(),
                      ),

                      SizedBox(height: 20.h),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
