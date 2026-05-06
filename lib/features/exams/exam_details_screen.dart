import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';
import 'package:platformexamapp/core/widgets/app_button.dart';
import 'package:platformexamapp/features/home/ui/home_screen.dart';

class ExamDetailsScreen extends StatefulWidget {
  final String examId;
  final String title;
  final int time;

  const ExamDetailsScreen({
    super.key,
    required this.examId,
    required this.title,
    required this.time,
  });

  @override
  State<ExamDetailsScreen> createState() => _ExamDetailsScreenState();
}

class _ExamDetailsScreenState extends State<ExamDetailsScreen> {
  int remainingSeconds = 0;
  Timer? timer;

  int currentIndex = 0;
  int score = 0;

  bool isLoaded = false;
  bool isSubmitting = false;

  List<QueryDocumentSnapshot> questions = [];
  Map<int, int> selectedAnswers = {};

  @override
  void initState() {
    super.initState();
    initExam();
  }

  // ---------------- INIT ----------------

  Future<void> initExam() async {
    await checkIfUserAlreadyTookExam();
    await loadQuestions();

    if (!mounted) return;

    if (questions.isNotEmpty) {
      startTimer(widget.time);
    }
  }

  Future<void> checkIfUserAlreadyTookExam() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final doc = await FirebaseFirestore.instance
        .collection("examAttempts")
        .doc("${uid}_${widget.examId}")
        .get();

    if (doc.exists && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showAlreadyTakenDialog();
      });
    }
  }

  Future<void> loadQuestions() async {
    final snap = await FirebaseFirestore.instance
        .collection("exams")
        .doc(widget.examId)
        .collection("questions")
        .get();

    questions = snap.docs;

    setState(() {
      isLoaded = true;
    });
  }

  // ---------------- TIMER ----------------

  void startTimer(int minutes) {
    remainingSeconds = minutes * 60;

    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;

      if (remainingSeconds <= 0) {
        t.cancel();
        submitExam();
      } else {
        setState(() => remainingSeconds--);
      }
    });
  }

  String formatTime(int seconds) {
    final min = seconds ~/ 60;
    final sec = seconds % 60;
    return "$min:${sec.toString().padLeft(2, '0')}";
  }

  // ---------------- ANSWERS ----------------

  void selectAnswer(int index) {
    setState(() {
      selectedAnswers[currentIndex] = index;
    });
  }

  void nextQuestion() {
    if (currentIndex < questions.length - 1) {
      setState(() => currentIndex++);
    }
  }

  void previousQuestion() {
    if (currentIndex > 0) {
      setState(() => currentIndex--);
    }
  }

  void calculateScore() {
    score = 0;

    for (int i = 0; i < questions.length; i++) {
      final correct = questions[i]["correctAnswer"];
      if (selectedAnswers[i] == correct) {
        score++;
      }
    }
  }

  // ---------------- SUBMIT ----------------

  Future<void> submitExam() async {
    if (isSubmitting) return;

    setState(() => isSubmitting = true);
    timer?.cancel();

    calculateScore();

    final uid = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance
        .collection("examAttempts")
        .doc("${uid}_${widget.examId}")
        .set({
          "userId": uid,
          "examId": widget.examId,
          "score": score,
          "timestamp": FieldValue.serverTimestamp(),
          "done": true,
        });

    if (!mounted) return;

    showResultDialog();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    if (!isLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (questions.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.whiteColor,
        appBar: AppBar(
          backgroundColor: AppColors.whiteColor,
          automaticallyImplyLeading: false,
          leading: IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => HomeScreen()),
              );
            },
            icon: Icon(Icons.arrow_back_ios),
          ),
          title: Text(widget.title),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.assignment_late, size: 80.r, color: Colors.grey),
              SizedBox(height: 20.h),
              Text(
                "No Exam Available",
                style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10.h),
              Text(
                "This exam has no questions yet",
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    final question = questions[currentIndex];
    final options = (question["options"] ?? []) as List;

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: AppColors.whiteColor,
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back_ios),
        ),
        title: Text(widget.title),
        actions: [
          Padding(
            padding: EdgeInsets.all(12.r),
            child: Center(
              child: Text(
                formatTime(remainingSeconds),
                style: TextStyle(fontSize: 25.sp),
              ),
            ),
          ),
        ],
      ),

      body: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: .start,
          children: [
            LinearProgressIndicator(
              color: AppColors.primaryColor,
              value: (currentIndex + 1) / questions.length,
            ),
            Image.asset(
              "assets/images/background.png",
              width: 80.w,
              height: 80.h,
            ),
            const SizedBox(height: 20),

            Center(
              child: Text(
                "Question ${currentIndex + 1} / ${questions.length}",
                style: TextStyle(fontSize: 18.sp),
              ),
            ),

            SizedBox(height: 10.h),

            Center(
              child: Text(
                question["question"] ?? "",
                style: TextStyle(fontSize: 20.sp),
              ),
            ),

            SizedBox(height: 20.h),

            Expanded(
              child: ListView.builder(
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final isSelected = selectedAnswers[currentIndex] == index;

                  return GestureDetector(
                    onTap: () => selectAnswer(index),
                    child: Container(
                      margin: EdgeInsets.only(bottom: 12.h),
                      padding: EdgeInsets.all(16.r),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.green.withOpacity(0.2)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? Colors.green
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(options[index].toString()),
                    ),
                  );
                },
              ),
            ),

            Row(
              children: [
                Expanded(
                  child: AppButton(
                    onPressed: currentIndex > 0 ? previousQuestion : null,
                    text: "Previous",
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: AppButton(
                    onPressed: currentIndex == questions.length - 1
                        ? submitExam
                        : nextQuestion,
                    text: currentIndex == questions.length - 1
                        ? "Submit"
                        : "Next",
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- PROFESSIONAL DIALOGS ----------------

  void showAlreadyTakenDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: AppColors.whiteColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Padding(
            padding: EdgeInsets.all(20.r),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock, color: Colors.red, size: 50.r),
                SizedBox(height: 15.h),
                Text(
                  "Not Allowed",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10.h),
                Text(
                  "You already took this exam.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                SizedBox(height: 20.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                        (route) => false,
                      );
                    },
                    child: Text(
                      "OK",
                      style: TextStyle(
                        fontSize: 15.sp,
                        color: AppColors.whiteColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void showResultDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Padding(
            padding: EdgeInsets.all(20.r),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.emoji_events, color: Colors.amber, size: 60.r),
                SizedBox(height: 15.h),
                Text(
                  "Exam Finished 🎉",
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10.h),
                Text(
                  "Your Score: $score / ${questions.length}",
                  style: TextStyle(fontSize: 16.sp),
                ),
                SizedBox(height: 20.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                        (route) => false,
                      );
                    },
                    child: Text(
                      "Back to Home",
                      style: TextStyle(
                        fontSize: 15.sp,
                        color: AppColors.whiteColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
