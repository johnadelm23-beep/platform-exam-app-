import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';
import 'package:platformexamapp/core/widgets/app_button.dart';
import 'package:platformexamapp/core/widgets/custom_text_form_field.dart';
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

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    final userDoc = await FirebaseFirestore.instance.collection("users").doc(currentUser.uid).get();
    if (userDoc.data()?["isAdmin"] != true) {
      _showError("Permission denied: Main Admin only.");
      return;
    }

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
        AppPageRoute(child: AddQuestionScreen(examId: examRef.id)),
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
                    "create_exam".tr(),
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
                              "create_your_exam".tr(),
                              style: TextStyle(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            SizedBox(height: 5.h),

                            Text(
                              "add_title_and_duration".tr(),
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 20.h),

                      CustomTextFormField(
                        hintText: "exam_title".tr(),
                        controller: titleController,
                      ),

                      SizedBox(height: 10.h),

                      CustomTextFormField(
                        hintText: "Time".tr(),
                        controller: timeController,
                        keyboardType: TextInputType.number,
                      ),

                      SizedBox(height: 30.h),

                      /// 🚀 BUTTON
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
