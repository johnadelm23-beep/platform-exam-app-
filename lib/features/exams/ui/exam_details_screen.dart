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
import 'package:platformexamapp/features/exams/data/exam_service.dart';
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
  bool isTerminating = false;
  bool isTerminated = false;

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
    if (isSubmitting || isTerminated || !isLoaded) return;

    // Detect when the user minimizes the app, moves to background, or switches tasks
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      terminateExam(
        reason: "App moved to background or student switched applications",
        violationType: "app_backgrounded",
      );
    }

    if (state == AppLifecycleState.resumed) {
      if (isTerminated) {
        showTerminatedDialog("exam_terminated_desc".tr());
      }
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) Navigator.pop(context);
      return;
    }

    final attemptResult = await ExamService.getAttemptStatus(
      userId: user.uid,
      examId: widget.examId,
      durationMinutes: widget.time,
    );

    if (!mounted) return;

    if (attemptResult.status == ExamAttemptStatus.terminated) {
      isTerminated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showTerminatedDialog(
          attemptResult.terminationReason ?? "exam_terminated_desc".tr(),
        );
      });
      return;
    }

    if (attemptResult.status == ExamAttemptStatus.completed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showAlreadyTakenDialog();
      });
      return;
    }

    await loadQuestions();

    if (!mounted) return;

    if (questions.isEmpty) {
      setState(() => isLoaded = true);
      return;
    }

    if (attemptResult.status == ExamAttemptStatus.inProgress) {
      // Restore previously saved draft answers
      selectedAnswers = Map<int, int>.from(attemptResult.savedAnswers);

      if (attemptResult.remainingSeconds <= 0) {
        // Time expired while away -> auto-submit immediately
        setState(() {
          isLoaded = true;
          remainingSeconds = 0;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          submitExam(isAutoSubmit: true);
        });
        return;
      } else {
        remainingSeconds = attemptResult.remainingSeconds;
      }
    } else {
      // Fresh start: Persist attempt on Firestore and locally
      remainingSeconds = widget.time * 60;
      await ExamService.startExamAttempt(
        userId: user.uid,
        examId: widget.examId,
        title: widget.title,
        durationMinutes: widget.time,
      );
    }

    startTimer();

    if (mounted) {
      setState(() => isLoaded = true);
    }
  }

  // ================= LOAD QUESTIONS =================
  Future<void> loadQuestions() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection("exams")
          .doc(widget.examId)
          .collection("questions")
          .get();

      final docs = snap.docs.toList();
      // Deterministic order if questions have order index, otherwise doc order
      docs.sort((a, b) {
        final dataA = a.data();
        final dataB = b.data();
        final orderA = dataA["order"] as num?;
        final orderB = dataB["order"] as num?;
        if (orderA != null && orderB != null) {
          return orderA.compareTo(orderB);
        }
        return a.id.compareTo(b.id);
      });

      questions = docs;
    } catch (e) {
      debugPrint("Error loading questions: $e");
      questions = [];
    }
  }

  // ================= TIMER =================
  void startTimer() {
    timer?.cancel();

    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }

      if (isSubmitting || isTerminated) {
        t.cancel();
        return;
      }

      if (remainingSeconds <= 1) {
        t.cancel();
        remainingSeconds = 0;
        setState(() {});
        autoSubmitOnTimeout();
      } else {
        setState(() => remainingSeconds--);
      }
    });
  }

  void autoSubmitOnTimeout() {
    if (!mounted || isSubmitting || isTerminated) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "time_expired".tr(),
          style: GoogleFonts.cairo(color: Colors.white),
        ),
        backgroundColor: AppColors.heartRed,
        duration: const Duration(seconds: 2),
      ),
    );

    submitExam(isAutoSubmit: true);
  }

  String formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return "$m:${s.toString().padLeft(2, '0')}";
  }

  // ================= ANSWERS =================
  void selectAnswer(int index) {
    if (isSubmitting || isTerminated) return;

    setState(() {
      selectedAnswers[currentIndex] = index;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      ExamService.saveDraftAnswers(
        userId: user.uid,
        examId: widget.examId,
        answers: selectedAnswers,
      );
    }
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
      final qData = questions[i].data() as Map<String, dynamic>;
      final correct = qData["correctAnswer"];
      if (selectedAnswers[i] == correct) {
        score++;
      }
    }
  }

  // ================= SUBMIT =================
  Future<void> submitExam({bool isAutoSubmit = false}) async {
    if (isSubmitting || isTerminated) return;

    setState(() => isSubmitting = true);
    timer?.cancel();

    calculateScore();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => isSubmitting = false);
      return;
    }

    try {
      await ExamService.submitExamAttempt(
        userId: user.uid,
        examId: widget.examId,
        title: widget.title,
        score: score,
        totalQuestions: questions.length,
      );

      if (mounted) {
        showResultDialog();
      }
    } catch (e) {
      debugPrint("Error submitting exam: $e");
      if (mounted) {
        setState(() => isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "${'submission_error'.tr()}: $e",
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: AppColors.heartRed,
            action: SnackBarAction(
              label: "retry".tr(),
              textColor: Colors.white,
              onPressed: () => submitExam(isAutoSubmit: isAutoSubmit),
            ),
          ),
        );
      }
    }
  }

  // ================= TERMINATE FOR VIOLATION =================
  Future<void> terminateExam({
    required String reason,
    required String violationType,
  }) async {
    if (isTerminating || isSubmitting || isTerminated) return;

    isTerminating = true;
    isTerminated = true;
    timer?.cancel();

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await ExamService.terminateExamAttempt(
        userId: user.uid,
        examId: widget.examId,
        title: widget.title,
        reason: reason,
        violationType: violationType,
      );
    }

    if (mounted) {
      showTerminatedDialog("exam_terminated_desc".tr());
    }
  }

  // ================= POP INTERCEPTION =================
  void _handleExitAttempt() {
    AppDialog.show(
      context: context,
      iconWidget: Icon(
        Icons.warning_amber_rounded,
        color: AppColors.heartRed,
        size: 36.r,
      ),
      iconColor: AppColors.heartRed,
      title: "exit_exam_title".tr(),
      description: "exit_exam_desc".tr(),
      confirmText: "leave_exam".tr(),
      confirmButtonColor: AppColors.heartRed,
      cancelText: "continue_exam".tr(),
      onConfirm: () {
        Navigator.pop(context); // close dialog
        terminateExam(
          reason: "Student voluntarily exited exam screen",
          violationType: "navigation_pop",
        );
      },
    );
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

    final q = questions[currentIndex].data() as Map<String, dynamic>;
    final options = (q["options"] ?? []) as List;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (isSubmitting || isTerminated || !isLoaded) return;
        _handleExitAttempt();
      },
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
                color: AppColors.softGold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: AppColors.softGold.withValues(alpha: 0.3),
                ),
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
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.05),
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
                      q["question"]?.toString() ?? "",
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
                              ? AppColors.softGold.withValues(alpha: 0.18)
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
                      onPressed: isSubmitting ? null : prev,
                      child: Text(
                        "previous".tr(),
                        style: GoogleFonts.cairo(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                          color: isSubmitting ? mutedColor : textColor,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: AppButton(
                      text: isSubmitting
                          ? "..."
                          : (currentIndex == questions.length - 1
                              ? "submit".tr()
                              : "next".tr()),
                      onPressed: isSubmitting
                          ? null
                          : (currentIndex == questions.length - 1
                              ? submitExam
                              : next),
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

  void showTerminatedDialog(String reason) {
    AppDialog.show(
      context: context,
      iconWidget: Icon(
        Icons.block_rounded,
        color: AppColors.heartRed,
        size: 36.r,
      ),
      iconColor: AppColors.heartRed,
      title: "exam_terminated".tr(),
      description: reason.isNotEmpty ? reason : "exam_terminated_desc".tr(),
      confirmText: "back_to_home".tr(),
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
