import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';
import 'package:platformexamapp/core/widgets/app_button.dart';
import 'package:platformexamapp/core/widgets/custom_text_form_field.dart';

class AddQuestionScreen extends StatefulWidget {
  final String examId;
  const AddQuestionScreen({super.key, required this.examId});

  @override
  State<AddQuestionScreen> createState() => _AddQuestionScreenState();
}

class _AddQuestionScreenState extends State<AddQuestionScreen> {
  final questionController = TextEditingController();

  final option1 = TextEditingController();
  final option2 = TextEditingController();
  final option3 = TextEditingController();
  final option4 = TextEditingController();

  int correctIndex = 0;

  Future<void> addQuestion() async {
    final question = questionController.text.trim();
    final op1 = option1.text.trim();
    final op2 = option2.text.trim();
    final op3 = option3.text.trim();
    final op4 = option4.text.trim();

    if (question.isEmpty ||
        op1.isEmpty ||
        op2.isEmpty ||
        op3.isEmpty ||
        op4.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please fill all fields", style: GoogleFonts.cairo()),
          backgroundColor: AppColors.heartRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (correctIndex < 0 || correctIndex > 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Please select correct answer",
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: AppColors.heartRed,
        ),
      );
      return;
    }

    await FirebaseFirestore.instance
        .collection("exams")
        .doc(widget.examId)
        .collection("questions")
        .add({
          "question": question,
          "options": [op1, op2, op3, op4],
          "correctAnswer": correctIndex,
        });

    questionController.clear();
    option1.clear();
    option2.clear();
    option3.clear();
    option4.clear();

    setState(() => correctIndex = 0);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "✅ Question added successfully",
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: AppColors.successGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget optionTile(TextEditingController controller, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextMain : AppColors.lightTextMain;
    final isSelected = correctIndex == index;

    return GestureDetector(
      onTap: () => setState(() => correctIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.softGold.withOpacity(0.18)
              : isDark
              ? AppColors.darkGlassSurface
              : AppColors.lightGlassSurface,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: isSelected
                ? AppColors.softGold
                : isDark
                ? AppColors.darkBorder
                : AppColors.lightBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: isSelected
                  ? AppColors.softGold
                  : AppColors.darkTextCaption,
              size: 20.r,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                controller.text.isEmpty
                    ? "Option ${index + 1}"
                    : controller.text,
                style: GoogleFonts.cairo(
                  fontSize: 14.sp,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: textColor,
                ),
              ),
            ),
          ],
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
                    "add_questions".tr(),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "question".tr(),
                        style: GoogleFonts.cairo(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),

                      SizedBox(height: 8.h),

                      CustomTextFormField(
                        hintText: "write_your_questions".tr(),
                        controller: questionController,
                        maxLines: 3,
                      ),

                      SizedBox(height: 20.h),

                      Text(
                        "options_tap".tr(),
                        style: GoogleFonts.cairo(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),

                      SizedBox(height: 8.h),

                      CustomTextFormField(
                        hintText: "option_1".tr(),
                        controller: option1,
                      ),
                      SizedBox(height: 4.h),
                      optionTile(option1, 0),

                      CustomTextFormField(
                        hintText: "option_2".tr(),
                        controller: option2,
                      ),
                      SizedBox(height: 4.h),
                      optionTile(option2, 1),

                      CustomTextFormField(
                        hintText: "option_3".tr(),
                        controller: option3,
                      ),
                      SizedBox(height: 4.h),
                      optionTile(option3, 2),

                      CustomTextFormField(
                        hintText: "option_4".tr(),
                        controller: option4,
                      ),
                      SizedBox(height: 4.h),
                      optionTile(option4, 3),

                      SizedBox(height: 20.h),

                      AppButton(
                        onPressed: addQuestion,
                        text: "add_question".tr(),
                      ),

                      SizedBox(height: 12.h),

                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: borderColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          minimumSize: Size(double.infinity, 50.h),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          "finish".tr(),
                          style: GoogleFonts.cairo(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ),
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
