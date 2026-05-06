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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      appBar: AppBar(
        backgroundColor: AppColors.whiteColor,
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back_ios),
        ),
        title: const Text("Add Exam"),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.r),
        child: Column(
          children: [
            Image.asset("assets/images/background.png"),
            CustomTextFormField(
              hintText: "Exam Title",
              keyboardType: .name,
              controller: titleController,
            ),

            SizedBox(height: 15.h),

            CustomTextFormField(
              hintText: "Time (minutes)",
              keyboardType: .number,
              controller: timeController,
            ),

            SizedBox(height: 30.h),

            AppButton(
              onPressed: () async {
                final examRef = await FirebaseFirestore.instance
                    .collection("exams")
                    .add({
                      "title": titleController.text,
                      "time": int.parse(timeController.text),
                    });

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddQuestionScreen(examId: examRef.id),
                  ),
                );
              },
              text: "Next → Add Questions",
            ),
          ],
        ),
      ),
    );
  }
}
