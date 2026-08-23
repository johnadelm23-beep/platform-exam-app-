import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';
import 'package:platformexamapp/core/theme/app_page_route.dart';
import 'package:platformexamapp/core/widgets/app_button.dart';
import 'package:platformexamapp/core/widgets/app_dialog.dart';
import 'package:platformexamapp/core/widgets/glass_card.dart';
import 'package:platformexamapp/core/widgets/loading_state.dart';
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

    if (doc.exists) {
      final data = doc.data();
      if (data != null && data["done"] == true && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showAlreadyTakenDialog();
        });
        return true;
      }
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
        AppPageRoute(child: const HomeScreen()),
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
          "examTitle": widget.title,
          "score": score,
          "done": true,
          "abandoned": false,
          "timestamp": FieldValue.serverTimestamp(),
          "createdAt": FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

    if (mounted) {
      showResultDialog();
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageBg = isDark ? AppColors.darkPageBg : AppColors.lightPageBg;
    final textColor = isDark ? AppColors.darkTextMain : AppColors.lightTextMain;
    final mutedColor = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;

    if (!isLoaded) {
      return Scaffold(backgroundColor: pageBg, body: const LoadingState());
    }

    if (questions.isEmpty) {
      return Scaffold(
        backgroundColor: pageBg,
        appBar: AppBar(
          backgroundColor: pageBg,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: textColor),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Text(
            "no_questions_found".tr(),
            style: GoogleFonts.cairo(color: textColor, fontSize: 16.sp),
          ),
        ),
      );
    }

    final q = questions[currentIndex];
    final options = (q["options"] ?? []) as List;

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: pageBg,
        appBar: AppBar(
          backgroundColor: pageBg,
          automaticallyImplyLeading: false,
          title: Text(
            widget.title,
            style: GoogleFonts.cairo(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          centerTitle: true,
          actions: [
            Container(
              margin: EdgeInsets.only(right: 16.w, left: 16.w),
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: AppColors.softGold.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: AppColors.softGold.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedClock01,
                    size: 16.r,
                    color: AppColors.softGold,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    formatTime(remainingSeconds),
                    style: GoogleFonts.cairo(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.softGold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: Padding(
          padding: EdgeInsets.all(16.r),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: LinearProgressIndicator(
                  color: AppColors.softGold,
                  backgroundColor: isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.black.withOpacity(0.05),
                  value: (currentIndex + 1) / questions.length,
                  minHeight: 6.h,
                ),
              ),
              SizedBox(height: 16.h),
              GlassCard(
                padding: EdgeInsets.all(16.r),
                borderRadius: 20.r,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "question_index".tr(
                            args: [
                              (currentIndex + 1).toString(),
                              questions.length.toString(),
                            ],
                          ),
                          style: GoogleFonts.cairo(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.softGold,
                          ),
                        ),
                        Image.asset(
                          "assets/images/background.png",
                          width: 40.w,
                          height: 40.h,
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      q["question"],
                      style: GoogleFonts.cairo(
                        fontSize: 17.sp,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: options.length,
                  itemBuilder: (c, i) {
                    final selected = selectedAnswers[currentIndex] == i;

                    return GestureDetector(
                      onTap: () => selectAnswer(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: EdgeInsets.only(bottom: 12.h),
                        padding: EdgeInsets.all(16.r),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.softGold.withOpacity(0.18)
                              : isDark
                              ? AppColors.darkGlassSurface
                              : AppColors.lightGlassSurface,
                          border: Border.all(
                            color: selected
                                ? AppColors.softGold
                                : isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                            width: selected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 22.r,
                              height: 22.r,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: selected
                                    ? AppColors.softGold
                                    : Colors.transparent,
                                border: Border.all(
                                  color: selected
                                      ? AppColors.softGold
                                      : mutedColor,
                                  width: 2,
                                ),
                              ),
                              child: selected
                                  ? Icon(
                                      Icons.check,
                                      size: 14.r,
                                      color: AppColors.cinematicNavy,
                                    )
                                  : null,
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Text(
                                options[i].toString(),
                                style: GoogleFonts.cairo(
                                  fontSize: 15.sp,
                                  fontWeight: selected
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                      ),
                      onPressed: prev,
                      child: Text(
                        "previous".tr(),
                        style: GoogleFonts.cairo(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: AppButton(
                      text: currentIndex == questions.length - 1
                          ? "submit".tr()
                          : "next".tr(),
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
    AppDialog.show(
      context: context,
      iconWidget: Icon(
        Icons.lock_rounded,
        color: AppColors.heartRed,
        size: 36.r,
      ),
      iconColor: AppColors.heartRed,
      title: "not_allowed".tr(),
      description: "already_took_exam".tr(),
      confirmText: "ok".tr(),
      confirmButtonColor: AppColors.heartRed,
      onConfirm: () {
        Navigator.pushAndRemoveUntil(
          context,
          AppPageRoute(child: const HomeScreen()),
          (route) => false,
        );
      },
    );
  }

  void showResultDialog() {
    AppDialog.show(
      context: context,
      iconWidget: Icon(
        Icons.emoji_events_rounded,
        color: AppColors.softGold,
        size: 36.r,
      ),
      iconColor: AppColors.softGold,
      title: "exam_finished".tr(),
      description: "your_score".tr(
        args: [score.toString(), questions.length.toString()],
      ),
      confirmText: "back_to_home".tr(),
      confirmButtonColor: AppColors.softGold,
      onConfirm: () {
        Navigator.pushAndRemoveUntil(
          context,
          AppPageRoute(child: const HomeScreen()),
          (route) => false,
        );
      },
    );
  }
}
