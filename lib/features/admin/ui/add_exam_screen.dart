import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';
import 'package:platformexamapp/core/widgets/app_button.dart';
import 'package:platformexamapp/core/widgets/custom_text_form_field.dart';
import 'package:platformexamapp/features/admin/ui/add_question_screen.dart';

class AddExamScreen extends StatefulWidget {
  const AddExamScreen({super.key});

  @override
  State<AddExamScreen> createState() => _AddExamScreenState();
}

class _AddExamScreenState extends State<AddExamScreen> {
  final titleController = TextEditingController();
  final timeController = TextEditingController();

  bool isLoading = false;

  /// ================= VALIDATION =================
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
        content: Text(msg),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// ================= CREATE EXAM =================
  Future<void> createExam() async {
    if (!validate()) return;

    setState(() => isLoading = true);

    try {
      final examRef = await FirebaseFirestore.instance.collection("exams").add({
        "title": titleController.text.trim(),
        "time": int.parse(timeController.text.trim()),
        "createdAt": FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AddQuestionScreen(examId: examRef.id),
        ),
      );
    } catch (e) {
      _showError("Something went wrong");
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor,

      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryColor,
                    // ignore: deprecated_member_use
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
                        // ignore: deprecated_member_use
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
                    "Create Exam",
                    style: TextStyle(
                      fontSize: 22.sp,
                      color: Colors.white,
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
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(25.r),
                    topRight: Radius.circular(25.r),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(height: 10.h),

                      Container(
                        padding: EdgeInsets.all(16.r),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16.r),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Image.asset(
                              "assets/images/background.png",
                              height: 120.h,
                            ),

                            SizedBox(height: 10.h),

                            Text(
                              "Create Your Exam ",
                              style: TextStyle(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            SizedBox(height: 5.h),

                            Text(
                              "Add title and duration before questions",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 20.h),

                      CustomTextFormField(
                        hintText: "Exam Title",
                        controller: titleController,
                      ),

                      SizedBox(height: 10.h),

                      CustomTextFormField(
                        hintText: "Time (minutes)",
                        controller: timeController,
                        keyboardType: TextInputType.number,
                      ),

                      SizedBox(height: 30.h),

                      /// 🚀 BUTTON
                      AppButton(
                        onPressed: isLoading ? null : createExam,
                        text: isLoading ? "Creating..." : "Next Add Questions",
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
