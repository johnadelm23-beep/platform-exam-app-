import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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

  /// ================= ADD QUESTION WITH VALIDATION =================
  Future<void> addQuestion() async {
    final question = questionController.text.trim();
    final op1 = option1.text.trim();
    final op2 = option2.text.trim();
    final op3 = option3.text.trim();
    final op4 = option4.text.trim();

    /// 🚫 Validation
    if (question.isEmpty ||
        op1.isEmpty ||
        op2.isEmpty ||
        op3.isEmpty ||
        op4.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please fill all fields"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    /// 🚫 Safety check (optional)
    if (correctIndex < 0 || correctIndex > 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select correct answer"),
          backgroundColor: Colors.red,
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

    /// ✅ Clear fields
    questionController.clear();
    option1.clear();
    option2.clear();
    option3.clear();
    option4.clear();

    setState(() => correctIndex = 0);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("✅ Question added successfully"),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// ================= OPTION TILE =================
  Widget optionTile(TextEditingController controller, int index) {
    final isSelected = correctIndex == index;

    return GestureDetector(
      onTap: () => setState(() => correctIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.withOpacity(0.15) : Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: isSelected ? Colors.green : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? Colors.green : Colors.grey,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                controller.text.isEmpty
                    ? "Option ${index + 1}"
                    : controller.text,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor,

      body: SafeArea(
        child: Column(
          children: [
            /// 🔵 HEADER (same as Home UI)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryColor,
                    AppColors.primaryColor.withOpacity(0.85),
                  ],
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: EdgeInsets.all(10.r),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),

                  SizedBox(width: 12.w),

                  Text(
                    "Add Question",
                    style: TextStyle(
                      fontSize: 22.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            /// ⚪ BODY
            Expanded(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(25.r),
                    topRight: Radius.circular(25.r),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Question",
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      SizedBox(height: 10.h),

                      CustomTextFormField(
                        hintText: "Write your question...",
                        controller: questionController,
                        maxLines: 3,
                      ),

                      SizedBox(height: 20.h),

                      /// 🎯 OPTIONS
                      Text(
                        "Options (Tap correct one)",
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      SizedBox(height: 10.h),

                      CustomTextFormField(
                        hintText: "Option 1",
                        controller: option1,
                      ),
                      optionTile(option1, 0),

                      CustomTextFormField(
                        hintText: "Option 2",
                        controller: option2,
                      ),
                      optionTile(option2, 1),

                      CustomTextFormField(
                        hintText: "Option 3",
                        controller: option3,
                      ),
                      optionTile(option3, 2),

                      CustomTextFormField(
                        hintText: "Option 4",
                        controller: option4,
                      ),
                      optionTile(option4, 3),

                      SizedBox(height: 20.h),

                      /// 🚀 BUTTONS
                      AppButton(onPressed: addQuestion, text: "Add Question"),

                      SizedBox(height: 10.h),

                      AppButton(
                        onPressed: () => Navigator.pop(context),
                        text: "Finish",
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
