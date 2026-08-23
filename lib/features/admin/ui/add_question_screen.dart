import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';
import 'package:platformexamapp/core/widgets/app_button.dart';
import 'package:platformexamapp/core/widgets/custom_text_form_field.dart';

class QuestionDraft {
  String question;
  List<String> options;
  int correctAnswer;

  QuestionDraft({
    required this.question,
    required this.options,
    required this.correctAnswer,
  });
}

class AddQuestionScreen extends StatefulWidget {
  final String examTitle;
  final int examTime;
  final String? examId;

  const AddQuestionScreen({
    super.key,
    required this.examTitle,
    required this.examTime,
    this.examId,
  });

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
  int? editingIndex;
  bool isPublishing = false;

  final List<QuestionDraft> draftQuestions = [];

  void addOrUpdateQuestion() {
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
      _showSnackBar("Please fill all fields", isError: true);
      return;
    }

    if (correctIndex < 0 || correctIndex > 3) {
      _showSnackBar("Please select correct answer", isError: true);
      return;
    }

    final draft = QuestionDraft(
      question: question,
      options: [op1, op2, op3, op4],
      correctAnswer: correctIndex,
    );

    setState(() {
      if (editingIndex != null) {
        draftQuestions[editingIndex!] = draft;
        editingIndex = null;
      } else {
        draftQuestions.add(draft);
      }
    });

    _clearInputs();

    _showSnackBar("✅ Question saved to draft", isError: false);
  }

  void editQuestion(int index) {
    final q = draftQuestions[index];
    setState(() {
      editingIndex = index;
      questionController.text = q.question;
      option1.text = q.options[0];
      option2.text = q.options[1];
      option3.text = q.options[2];
      option4.text = q.options[3];
      correctIndex = q.correctAnswer;
    });
  }

  void deleteQuestion(int index) {
    setState(() {
      if (editingIndex == index) {
        editingIndex = null;
        _clearInputs();
      }
      draftQuestions.removeAt(index);
    });
  }

  void _clearInputs() {
    questionController.clear();
    option1.clear();
    option2.clear();
    option3.clear();
    option4.clear();
    setState(() {
      correctIndex = 0;
    });
  }

  Future<void> finishAndPublishExam() async {
    if (draftQuestions.isEmpty) {
      _showSnackBar("Please add at least one question before publishing", isError: true);
      return;
    }

    setState(() => isPublishing = true);

    try {
      final examRef = await FirebaseFirestore.instance.collection("exams").add({
        "title": widget.examTitle,
        "time": widget.examTime,
        "createdAt": FieldValue.serverTimestamp(),
      });

      final batch = FirebaseFirestore.instance.batch();
      for (var q in draftQuestions) {
        final qRef = examRef.collection("questions").doc();
        batch.set(qRef, {
          "question": q.question,
          "options": q.options,
          "correctAnswer": q.correctAnswer,
        });
      }

      await batch.commit();

      if (!mounted) return;

      _showSnackBar("✅ Exam published successfully!", isError: false);

      // Pop back to exams list screen (pop twice: AddQuestionScreen & AddExamScreen)
      Navigator.of(context).pop();
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        _showSnackBar("Failed to publish exam: $e", isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => isPublishing = false);
      }
    }
  }

  void _showSnackBar(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.cairo()),
        backgroundColor: isError ? AppColors.heartRed : AppColors.successGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
              ? AppColors.softGold.withValues(alpha: 0.18)
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
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "add_questions".tr(),
                          style: GoogleFonts.cairo(
                            fontSize: 20.sp,
                            color: textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.examTitle,
                          style: GoogleFonts.cairo(
                            fontSize: 12.sp,
                            color: AppColors.softGold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
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
                        editingIndex != null ? "تعديل السؤال" : "question".tr(),
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

                      SizedBox(height: 16.h),

                      AppButton(
                        onPressed: addOrUpdateQuestion,
                        text: editingIndex != null
                            ? "تحديث السؤال"
                            : "add_question".tr(),
                      ),

                      if (editingIndex != null) ...[
                        SizedBox(height: 8.h),
                        Center(
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                editingIndex = null;
                                _clearInputs();
                              });
                            },
                            child: Text(
                              "إلغاء التعديل",
                              style: GoogleFonts.cairo(color: AppColors.heartRed),
                            ),
                          ),
                        ),
                      ],

                      SizedBox(height: 24.h),
                      Divider(color: borderColor),
                      SizedBox(height: 12.h),

                      // Draft Questions Review Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "الأسئلة المضافة (${draftQuestions.length})",
                            style: GoogleFonts.cairo(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),

                      if (draftQuestions.isEmpty)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          child: Center(
                            child: Text(
                              "لم يتم إضافة أسئلة بعد",
                              style: GoogleFonts.cairo(
                                color: mutedColor,
                                fontSize: 13.sp,
                              ),
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: draftQuestions.length,
                          itemBuilder: (context, index) {
                            final q = draftQuestions[index];
                            return Container(
                              margin: EdgeInsets.only(bottom: 10.h),
                              padding: EdgeInsets.all(12.r),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkGlassSurface
                                    : AppColors.lightGlassSurface,
                                borderRadius: BorderRadius.circular(14.r),
                                border: Border.all(color: borderColor),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 14.r,
                                    backgroundColor: AppColors.softGold,
                                    child: Text(
                                      "${index + 1}",
                                      style: GoogleFonts.cairo(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12.sp,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 10.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          q.question,
                                          style: GoogleFonts.cairo(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14.sp,
                                            color: textColor,
                                          ),
                                        ),
                                        SizedBox(height: 4.h),
                                        Text(
                                          "الإجابة الصحيحة: ${q.options[q.correctAnswer]}",
                                          style: GoogleFonts.cairo(
                                            fontSize: 12.sp,
                                            color: AppColors.successGreen,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const HugeIcon(
                                      icon: HugeIcons.strokeRoundedEdit02,
                                      color: Colors.blue,
                                    ),
                                    onPressed: () => editQuestion(index),
                                  ),
                                  IconButton(
                                    icon: const HugeIcon(
                                      icon: HugeIcons.strokeRoundedDelete01,
                                      color: AppColors.heartRed,
                                    ),
                                    onPressed: () => deleteQuestion(index),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                      SizedBox(height: 24.h),

                      // Final Publish Button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.successGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          minimumSize: Size(double.infinity, 52.h),
                        ),
                        onPressed: isPublishing ? null : finishAndPublishExam,
                        child: isPublishing
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                "إنهاء ونشر الامتحان",
                                style: GoogleFonts.cairo(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
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
