import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
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
    await FirebaseFirestore.instance
        .collection("exams")
        .doc(widget.examId)
        .collection("questions")
        .add({
          "question": questionController.text,
          "options": [option1.text, option2.text, option3.text, option4.text],
          "correctAnswer": correctIndex,
        });

    questionController.clear();
    option1.clear();
    option2.clear();
    option3.clear();
    option4.clear();

    setState(() {
      correctIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      appBar: AppBar(
        title: const Text("Add Questions"),
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back_ios),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          spacing: 10,
          children: [
            CustomTextFormField(
              hintText: "add question",
              controller: questionController,
            ),
            const SizedBox(height: 15),

            CustomTextFormField(hintText: "Option 1", controller: option1),
            CustomTextFormField(hintText: "Option 2", controller: option2),
            CustomTextFormField(hintText: "Option 3", controller: option3),
            CustomTextFormField(hintText: "Option 4", controller: option4),
            const SizedBox(height: 15),

            DropdownButton<int>(
              focusColor: Colors.white,
              value: correctIndex,
              items: const [
                DropdownMenuItem(value: 0, child: Text("Correct: Option 1")),
                DropdownMenuItem(value: 1, child: Text("Correct: Option 2")),
                DropdownMenuItem(value: 2, child: Text("Correct: Option 3")),
                DropdownMenuItem(value: 3, child: Text("Correct: Option 4")),
              ],
              onChanged: (value) {
                setState(() {
                  correctIndex = value!;
                });
              },
            ),

            const SizedBox(height: 20),

            AppButton(onPressed: addQuestion, text: "Add Question"),

            const SizedBox(height: 10),

            AppButton(
              onPressed: () {
                Navigator.pop(context);
              },
              text: "Finish",
            ),
          ],
        ),
      ),
    );
  }
}
