import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';
import 'package:platformexamapp/core/theme/app_page_route.dart';
import 'package:platformexamapp/core/widgets/app_dialog.dart';
import 'package:platformexamapp/core/widgets/glass_card.dart';
import 'package:platformexamapp/core/widgets/loading_state.dart';
import 'package:platformexamapp/features/games/data/models/game_model.dart';
import 'package:platformexamapp/features/games/data/services/game_service.dart';
import 'package:platformexamapp/features/games/ui/final_podium_screen.dart';
import 'package:platformexamapp/features/games/ui/live_leaderboard_screen.dart';
import 'package:platformexamapp/features/games/ui/question_result_screen.dart';
import 'package:platformexamapp/features/games/ui/widgets/live_authoritative_timer.dart';

class GamePlayScreen extends StatefulWidget {
  final String gameId;

  const GamePlayScreen({
    super.key,
    required this.gameId,
  });

  @override
  State<GamePlayScreen> createState() => _GamePlayScreenState();
}

class _GamePlayScreenState extends State<GamePlayScreen> with WidgetsBindingObserver {
  late final Stream<DocumentSnapshot> _gameStream;
  Stream<DocumentSnapshot>? _teamAnswerStream;

  Timer? _countdownTimer;
  int _secondsLeft = 15;
  int _totalQuestionTime = 15;

  bool _isSubmitting = false;
  int? _selectedOptionIndex;
  GameTeamModel? _myTeam;
  String _myUserId = "";

  final List<Color> _optionColors = const [
    Color(0xFF2563EB), // Royal Blue
    Color(0xFFDC2626), // Crimson Red
    Color(0xFFD97706), // Amber Gold
    Color(0xFF16A34A), // Forest Green
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _myUserId = FirebaseAuth.instance.currentUser?.uid ?? "";
    _gameStream = FirebaseFirestore.instance.collection("games").doc(widget.gameId).snapshots();
    _loadUserTeam();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _recalculateServerTimer();
    }
  }

  Future<void> _loadUserTeam() async {
    try {
      final userTeamDoc = await FirebaseFirestore.instance
          .collection("games")
          .doc(widget.gameId)
          .collection("userTeams")
          .doc(_myUserId)
          .get();

      if (userTeamDoc.exists) {
        final teamId = userTeamDoc.data()?["teamId"] as String? ?? "";
        if (teamId.isNotEmpty) {
          final teamDoc = await FirebaseFirestore.instance
              .collection("games")
              .doc(widget.gameId)
              .collection("teams")
              .doc(teamId)
              .get();

          if (teamDoc.exists) {
            setState(() {
              _myTeam = GameTeamModel.fromSnapshot(teamDoc);
            });
          }
        }
      }
    } catch (_) {}
  }

  void _startLocalTimer(GameModel game) {
    _countdownTimer?.cancel();

    if (game.isPaused) {
      setState(() => _secondsLeft = game.pausedRemainingSeconds);
      return;
    }

    final endTime = game.questionEndTime?.toDate();
    if (endTime != null) {
      final diff = endTime.difference(DateTime.now()).inSeconds;
      _secondsLeft = diff.clamp(0, game.timePerQuestion).toInt();
      _totalQuestionTime = game.timePerQuestion;
    } else {
      _secondsLeft = game.timePerQuestion;
    }

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      _recalculateServerTimer();
    });
  }

  void _recalculateServerTimer() async {
    final doc = await FirebaseFirestore.instance.collection("games").doc(widget.gameId).get();
    if (!doc.exists || !mounted) return;
    final game = GameModel.fromSnapshot(doc);

    if (game.isPaused) {
      setState(() => _secondsLeft = game.pausedRemainingSeconds);
      return;
    }

    final endTime = game.questionEndTime?.toDate();
    if (endTime != null) {
      final remaining = endTime.difference(DateTime.now()).inSeconds;
      setState(() {
        _secondsLeft = remaining.clamp(0, game.timePerQuestion).toInt();
      });
    }
  }

  Future<void> _submitTeamAnswer(int optionIndex, GameQuestionModel question, GameModel game) async {
    if (_isSubmitting || _myTeam == null || _secondsLeft <= 0) return;

    setState(() {
      _isSubmitting = true;
      _selectedOptionIndex = optionIndex;
    });

    try {
      final userDoc = await FirebaseFirestore.instance.collection("users").doc(_myUserId).get();
      final userName = userDoc.data()?["name"] as String? ?? "Player";

      await GameService().submitTeamAnswer(
        gameId: widget.gameId,
        questionIndex: game.currentQuestionIndex,
        teamId: _myTeam!.id,
        teamName: _myTeam!.name,
        teamEmoji: _myTeam!.emoji,
        userId: _myUserId,
        userName: userName,
        selectedOption: optionIndex,
      );

      if (mounted) {
        _showSnackBar("answer_submitted".tr(), isError: false);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(e.toString().replaceAll("Exception:", "").trim(), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _handleGameStatusTransitions(GameModel game) {
    if (game.status == "question_result") {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          AppPageRoute(
            child: QuestionResultScreen(
              gameId: widget.gameId,
              questionIndex: game.currentQuestionIndex,
              teamId: _myTeam?.id ?? "",
            ),
          ),
        );
      });
    } else if (game.status == "question_leaderboard") {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          AppPageRoute(
            child: LiveLeaderboardScreen(gameId: widget.gameId),
          ),
        );
      });
    } else if (game.status == "finished") {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          AppPageRoute(
            child: FinalPodiumScreen(gameId: widget.gameId),
          ),
        );
      });
    }
  }

  Future<bool> _onWillPop() async {
    bool shouldLeave = false;
    AppDialog.show(
      context: context,
      iconWidget: HugeIcon(
        icon: HugeIcons.strokeRoundedAlert02,
        color: AppColors.softGold,
        size: 36.r,
      ),
      iconColor: AppColors.softGold,
      title: "leave_game_title".tr(),
      description: "leave_game_desc".tr(),
      confirmText: "leave".tr(),
      cancelText: "stay".tr(),
      confirmButtonColor: AppColors.heartRed,
      onConfirm: () {
        shouldLeave = true;
        Navigator.pop(context);
        Navigator.pop(context);
      },
    );
    return shouldLeave;
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageBg = isDark ? AppColors.darkPageBg : AppColors.lightPageBg;
    final textColor = isDark ? AppColors.darkTextMain : AppColors.lightTextMain;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: StreamBuilder<DocumentSnapshot>(
        stream: _gameStream,
        builder: (context, gameSnap) {
          if (!gameSnap.hasData) return const Scaffold(body: LoadingState());
          final game = GameModel.fromSnapshot(gameSnap.data!);

          _handleGameStatusTransitions(game);

          if (_countdownTimer == null || !_countdownTimer!.isActive) {
            _startLocalTimer(game);
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("games")
                .doc(widget.gameId)
                .collection("questions")
                .orderBy("order")
                .snapshots(),
            builder: (context, qSnap) {
              if (!qSnap.hasData) return const Scaffold(body: LoadingState());
              final qDocs = qSnap.data!.docs;

              if (qDocs.isEmpty || game.currentQuestionIndex >= qDocs.length) {
                return const Scaffold(body: LoadingState());
              }

              final question = GameQuestionModel.fromSnapshot(qDocs[game.currentQuestionIndex]);

              // Check if Team already answered this question
              final answerDocId = "q${game.currentQuestionIndex}_team_${_myTeam?.id ?? ''}";
              _teamAnswerStream ??= FirebaseFirestore.instance
                  .collection("games")
                  .doc(widget.gameId)
                  .collection("answers")
                  .doc(answerDocId)
                  .snapshots();

              return Scaffold(
                backgroundColor: pageBg,
                body: SafeArea(
                  child: Column(
                    children: [
                      /// Header Bar with Team Identity & Question Index
                      Padding(
                        padding: EdgeInsets.all(16.r),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: _onWillPop,
                              child: Container(
                                padding: EdgeInsets.all(10.r),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.08)
                                      : Colors.black.withOpacity(0.05),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.arrow_back_ios,
                                  color: textColor,
                                  size: 18.r,
                                ),
                              ),
                            ),
                            SizedBox(width: 10.w),
                            if (_myTeam != null)
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                                decoration: BoxDecoration(
                                  color: AppColors.softGold.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Row(
                                  children: [
                                    Text(_myTeam!.emoji, style: TextStyle(fontSize: 16.sp)),
                                    SizedBox(width: 6.w),
                                    Text(
                                      _myTeam!.name,
                                      style: GoogleFonts.cairo(fontSize: 13.sp, fontWeight: FontWeight.bold, color: AppColors.softGold),
                                    ),
                                  ],
                                ),
                              ),
                            const Spacer(),
                            Text(
                              "question_n".tr(args: ["${game.currentQuestionIndex + 1}/${qDocs.length}"]),
                              style: GoogleFonts.cairo(
                                fontSize: 16.sp,
                                color: textColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      /// Visual Countdown Timer Ring
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: StreamBuilder<DocumentSnapshot>(
                          stream: _teamAnswerStream,
                          builder: (context, answerSnap) {
                            return LiveAuthoritativeTimer(
                              endTime: game.questionEndTime?.toDate() ?? DateTime.now().add(Duration(seconds: game.timePerQuestion)),
                              totalSeconds: game.timePerQuestion,
                              isPaused: game.isPaused,
                              onTimeUp: () {},
                            );
                          },
                        ),
                      ),

                      SizedBox(height: 16.h),

                      /// Active Question & Color-Coded Choices Container
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(20.r),
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
                            border: Border(top: BorderSide(color: borderColor, width: 1)),
                          ),
                          child: StreamBuilder<DocumentSnapshot>(
                            stream: _teamAnswerStream,
                            builder: (context, answerSnap) {
                              final hasTeamAnswered = answerSnap.data?.exists ?? false;
                              final savedOption = (answerSnap.data?.data() as Map<String, dynamic>?)?["selectedOption"] as int?;

                              return Column(
                                children: [
                                  /// Question Text Card
                                  GlassCard(
                                    padding: EdgeInsets.all(20.r),
                                    borderRadius: 24.r,
                                    child: Center(
                                      child: Text(
                                        question.questionText,
                                        style: GoogleFonts.cairo(
                                          fontSize: 18.sp,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                          height: 1.4,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),

                                  if (hasTeamAnswered) ...[
                                    SizedBox(height: 12.h),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                                      decoration: BoxDecoration(
                                        color: AppColors.successGreen.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(12.r),
                                      ),
                                      child: Text(
                                        "team_answered".tr(),
                                        style: GoogleFonts.cairo(
                                          fontSize: 13.sp,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.successGreen,
                                        ),
                                      ),
                                    ),
                                  ],

                                  const Spacer(),

                                  /// 4 Choice Buttons
                                  GridView.count(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 12.w,
                                    mainAxisSpacing: 12.h,
                                    childAspectRatio: 1.8,
                                    children: List.generate(question.options.length, (optIdx) {
                                      final isSelected = (_selectedOptionIndex == optIdx) || (savedOption == optIdx);
                                      final btnColor = _optionColors[optIdx % _optionColors.length];

                                      return ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: btnColor,
                                          elevation: isSelected ? 8 : 2,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(18.r),
                                            side: isSelected
                                                ? const BorderSide(color: Colors.white, width: 3)
                                                : BorderSide.none,
                                          ),
                                        ),
                                        onPressed: (hasTeamAnswered || _secondsLeft <= 0 || game.isPaused)
                                            ? null
                                            : () => _submitTeamAnswer(optIdx, question, game),
                                        child: Text(
                                          question.options[optIdx],
                                          style: GoogleFonts.cairo(
                                            fontSize: 15.sp,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      );
                                    }),
                                  ),

                                  SizedBox(height: 10.h),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
