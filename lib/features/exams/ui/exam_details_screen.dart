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

class _ExamDetailsScreenState extends State<ExamDetailsScreen>
    with WidgetsBindingObserver {
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
    WidgetsBinding.instance.addObserver(this);
    initExam();
  }

  // ================= LIFECYCLE CONTROL =================
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      // 🔥 المستخدم خرج من التطبيق
      FirebaseFirestore.instance
          .collection("examAttempts")
          .doc("${uid}_${widget.examId}")
          .set({
            "userId": uid,
            "examId": widget.examId,
            "abandoned": true,
            "timestamp": FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    }

    if (state == AppLifecycleState.resumed) {
      checkIfAbandoned();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    timer?.cancel();
    super.dispose();
  }

  // ================= INIT =================
  Future<void> initExam() async {
    final blocked = await checkIfUserAlreadyTookExam();

    if (blocked) return;

    await loadQuestions();

    if (questions.isNotEmpty) {
      startTimer(widget.time);
    }

    setState(() => isLoaded = true);
  }

  Future<bool> checkIfUserAlreadyTookExam() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final doc = await FirebaseFirestore.instance
        .collection("examAttempts")
        .doc("${uid}_${widget.examId}")
        .get();

    if (doc.exists && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showAlreadyTakenDialog();
      });
      return true;
    }

    return false;
  }

  Future<void> checkIfAbandoned() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final doc = await FirebaseFirestore.instance
        .collection("examAttempts")
        .doc("${uid}_${widget.examId}")
        .get();

    final data = doc.data();

    if (data != null && data["abandoned"] == true && mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    }
  }

  // ================= LOAD QUESTIONS =================
  Future<void> loadQuestions() async {
    final snap = await FirebaseFirestore.instance
        .collection("exams")
        .doc(widget.examId)
        .collection("questions")
        .get();

    questions = snap.docs;
  }

  // ================= TIMER =================
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
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return "$m:${s.toString().padLeft(2, '0')}";
  }

  // ================= ANSWERS =================
  void selectAnswer(int index) {
    setState(() {
      selectedAnswers[currentIndex] = index;
    });
  }

  void next() {
    if (currentIndex < questions.length - 1) {
      setState(() => currentIndex++);
    }
  }

  void prev() {
    if (currentIndex > 0) {
      setState(() => currentIndex--);
    }
  }

  void calculateScore() {
    score = 0;

    for (int i = 0; i < questions.length; i++) {
      if (selectedAnswers[i] == questions[i]["correctAnswer"]) {
        score++;
      }
    }
  }

  // ================= SUBMIT =================
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
          "done": true,
          "abandoned": false,
          "timestamp": FieldValue.serverTimestamp(),
        });

    showResultDialog();
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    if (!isLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final q = questions[currentIndex];
    final options = (q["options"] ?? []) as List;

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.white,

        appBar: AppBar(
          backgroundColor: Colors.white,
          automaticallyImplyLeading: false,
          title: Text(widget.title, style: TextStyle(fontSize: 18.sp)),
          centerTitle: true,
          actions: [
            Padding(
              padding: EdgeInsets.all(12.r),
              child: Text(
                formatTime(remainingSeconds),
                style: TextStyle(fontSize: 18.sp),
              ),
            ),
          ],
        ),

        body: Padding(
          padding: EdgeInsets.all(16.r),
          child: Column(
            children: [
              LinearProgressIndicator(
                color: AppColors.primaryColor,
                value: (currentIndex + 1) / questions.length,
              ),

              SizedBox(height: 20.h),
              Row(
                mainAxisAlignment: .start,
                children: [
                  Image.asset(
                    "assets/images/background.png",
                    width: 70.w,
                    height: 70.h,
                  ),
                ],
              ),

              Text(
                "Question ${currentIndex + 1}/${questions.length}",
                style: TextStyle(fontSize: 18.sp),
              ),

              SizedBox(height: 20.h),

              Text(
                q["question"],
                style: TextStyle(fontSize: 18.sp),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 20.h),

              Expanded(
                child: ListView.builder(
                  itemCount: options.length,
                  itemBuilder: (c, i) {
                    final selected = selectedAnswers[currentIndex] == i;

                    return GestureDetector(
                      onTap: () => selectAnswer(i),
                      child: Container(
                        margin: EdgeInsets.only(bottom: 10.h),
                        padding: EdgeInsets.all(14.r),
                        decoration: BoxDecoration(
                          color: selected
                              ? Colors.green.withOpacity(0.2)
                              : Colors.white,
                          border: Border.all(
                            color: selected ? Colors.green : Colors.grey,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          options[i].toString(),
                          style: TextStyle(fontSize: 15.sp),
                        ),
                      ),
                    );
                  },
                ),
              ),

              Row(
                children: [
                  Expanded(
                    child: AppButton(text: "Previous", onPressed: prev),
                  ),

                  SizedBox(width: 10.w),

                  Expanded(
                    child: AppButton(
                      text: currentIndex == questions.length - 1
                          ? "Submit"
                          : "Next",
                      onPressed: currentIndex == questions.length - 1
                          ? submitExam
                          : next,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= DIALOGS =================
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
                        fontWeight: .bold,
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
                        fontWeight: .bold,
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
