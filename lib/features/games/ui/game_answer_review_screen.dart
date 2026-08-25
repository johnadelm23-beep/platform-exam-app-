import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';
import 'package:platformexamapp/core/widgets/empty_state.dart';
import 'package:platformexamapp/core/widgets/glass_card.dart';
import 'package:platformexamapp/core/widgets/loading_state.dart';
import 'package:platformexamapp/features/games/data/models/game_model.dart';

class GameAnswerReviewScreen extends StatefulWidget {
  final String gameId;
  final String? teamId;

  const GameAnswerReviewScreen({
    super.key,
    required this.gameId,
    this.teamId,
  });

  @override
  State<GameAnswerReviewScreen> createState() => _GameAnswerReviewScreenState();
}

class _GameAnswerReviewScreenState extends State<GameAnswerReviewScreen> {
  late final Stream<DocumentSnapshot> _gameStream;
  late final Stream<QuerySnapshot> _questionsStream;
  late final Stream<QuerySnapshot> _answersStream;

  String _currentUserId = "";
  String? _userTeamId;

  final List<Color> _optionColors = const [
    Color(0xFF2563EB), // Royal Blue
    Color(0xFFDC2626), // Crimson Red
    Color(0xFFD97706), // Amber Gold
    Color(0xFF16A34A), // Forest Green
  ];

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";
    _userTeamId = widget.teamId;

    _gameStream = FirebaseFirestore.instance.collection("games").doc(widget.gameId).snapshots();
    _questionsStream = FirebaseFirestore.instance
        .collection("games")
        .doc(widget.gameId)
        .collection("questions")
        .orderBy("order")
        .snapshots();

    _answersStream = FirebaseFirestore.instance
        .collection("games")
        .doc(widget.gameId)
        .collection("answers")
        .snapshots();

    if (_userTeamId == null || _userTeamId!.isEmpty) {
      _resolveUserTeam();
    }
  }

  Future<void> _resolveUserTeam() async {
    try {
      final userTeamDoc = await FirebaseFirestore.instance
          .collection("games")
          .doc(widget.gameId)
          .collection("userTeams")
          .doc(_currentUserId)
          .get();

      if (userTeamDoc.exists && mounted) {
        setState(() {
          _userTeamId = userTeamDoc.data()?["teamId"] as String?;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageBg = isDark ? AppColors.darkPageBg : AppColors.lightPageBg;
    final textColor = isDark ? AppColors.darkTextMain : AppColors.lightTextMain;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Scaffold(
      backgroundColor: pageBg,
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: _gameStream,
          builder: (context, gameSnap) {
            if (!gameSnap.hasData) return const LoadingState();
            if (!gameSnap.data!.exists) {
              return EmptyState(
                title: "Game not found",
                hugeIcon: HugeIcons.strokeRoundedAlert02,
              );
            }

            final game = GameModel.fromSnapshot(gameSnap.data!);

            return StreamBuilder<QuerySnapshot>(
              stream: _questionsStream,
              builder: (context, questionsSnap) {
                if (!questionsSnap.hasData) return const LoadingState();

                final qDocs = questionsSnap.data?.docs ?? [];
                if (qDocs.isEmpty) {
                  return EmptyState(
                    title: "Answer review is not available for this attempt.",
                    hugeIcon: HugeIcons.strokeRoundedTask01,
                  );
                }

                final questions = qDocs.map((d) => GameQuestionModel.fromSnapshot(d)).toList();

                return StreamBuilder<QuerySnapshot>(
                  stream: _answersStream,
                  builder: (context, answersSnap) {
                    final answerDocs = answersSnap.data?.docs ?? [];
                    final List<GameTeamAnswerModel> allAnswers =
                        answerDocs.map((d) => GameTeamAnswerModel.fromSnapshot(d)).toList();

                    // Filter answers for the player's team (or user id)
                    final Map<int, GameTeamAnswerModel> answerMap = {};
                    for (var ans in allAnswers) {
                      if (_userTeamId != null && _userTeamId!.isNotEmpty) {
                        if (ans.teamId == _userTeamId) {
                          answerMap[ans.questionIndex] = ans;
                        }
                      } else if (ans.userId == _currentUserId) {
                        answerMap[ans.questionIndex] = ans;
                      }
                    }

                    int correctCount = 0;
                    int wrongCount = 0;
                    int unansweredCount = 0;
                    int totalPoints = 0;

                    for (int i = 0; i < questions.length; i++) {
                      final ans = answerMap[i];
                      if (ans == null || ans.selectedOption < 0) {
                        unansweredCount++;
                      } else if (ans.isCorrect) {
                        correctCount++;
                        totalPoints += ans.pointsEarned;
                      } else {
                        wrongCount++;
                      }
                    }

                    return Column(
                      children: [
                        /// Header Bar
                        Padding(
                          padding: EdgeInsets.all(16.r),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  padding: EdgeInsets.all(10.r),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withOpacity(0.08)
                                        : Colors.black.withOpacity(0.05),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.arrow_back_ios_rounded,
                                    color: textColor,
                                    size: 18.r,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Review Answers",
                                      style: GoogleFonts.cairo(
                                        fontSize: 20.sp,
                                        fontWeight: FontWeight.w900,
                                        color: textColor,
                                      ),
                                    ),
                                    Text(
                                      game.title.isNotEmpty ? game.title : "Quiz Review",
                                      style: GoogleFonts.cairo(
                                        fontSize: 12.sp,
                                        color: mutedColor,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        /// Performance Overview Banner
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: GlassCard(
                            padding: EdgeInsets.all(16.r),
                            borderRadius: 20.r,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildSummaryItem(
                                  "Score",
                                  "$totalPoints pts",
                                  AppColors.softGold,
                                  HugeIcons.strokeRoundedAward01,
                                  textColor,
                                ),
                                _buildSummaryItem(
                                  "Correct",
                                  "$correctCount / ${questions.length}",
                                  AppColors.successGreen,
                                  HugeIcons.strokeRoundedCheckmarkCircle02,
                                  textColor,
                                ),
                                _buildSummaryItem(
                                  "Wrong",
                                  "$wrongCount",
                                  AppColors.heartRed,
                                  HugeIcons.strokeRoundedCancel01,
                                  textColor,
                                ),
                                _buildSummaryItem(
                                  "Unanswered",
                                  "$unansweredCount",
                                  Colors.amber.shade700,
                                  HugeIcons.strokeRoundedHelpCircle,
                                  textColor,
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: 14.h),

                        /// Question List Review
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                            decoration: BoxDecoration(
                              color: surfaceColor,
                              borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
                              border: Border(top: BorderSide(color: borderColor, width: 1)),
                            ),
                            child: Column(
                              children: [
                                Expanded(
                                  child: ListView.separated(
                                    physics: const BouncingScrollPhysics(),
                                    itemCount: questions.length,
                                    separatorBuilder: (_, __) => SizedBox(height: 16.h),
                                    itemBuilder: (context, index) {
                                      final question = questions[index];
                                      final ans = answerMap[index];

                                      return _buildQuestionReviewCard(
                                        index: index,
                                        question: question,
                                        answer: ans,
                                        isDark: isDark,
                                        textColor: textColor,
                                        mutedColor: mutedColor,
                                        borderColor: borderColor,
                                      );
                                    },
                                  ),
                                ),
                                SizedBox(height: 12.h),
                                SizedBox(
                                  width: double.infinity,
                                  height: 52.h,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.softGold,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                                      elevation: 2,
                                    ),
                                    icon: const Icon(Icons.home_rounded, color: Colors.black87),
                                    label: Text(
                                      "Back to Home",
                                      style: GoogleFonts.cairo(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    onPressed: () {
                                      Navigator.of(context).popUntil((route) => route.isFirst);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    String title,
    String val,
    Color color,
    List<List<dynamic>> iconData,
    Color textColor,
  ) {
    return Column(
      children: [
        HugeIcon(icon: iconData, color: color, size: 20.r),
        SizedBox(height: 4.h),
        Text(
          val,
          style: GoogleFonts.cairo(fontSize: 14.sp, fontWeight: FontWeight.w900, color: color),
        ),
        Text(
          title,
          style: GoogleFonts.cairo(fontSize: 11.sp, color: textColor.withOpacity(0.7)),
        ),
      ],
    );
  }

  Widget _buildQuestionReviewCard({
    required int index,
    required GameQuestionModel question,
    required GameTeamAnswerModel? answer,
    required bool isDark,
    required Color textColor,
    required Color mutedColor,
    required Color borderColor,
  }) {
    final bool hasAnswered = answer != null && answer.selectedOption >= 0;
    final int selectedIdx = hasAnswered ? answer.selectedOption : -1;
    final bool isCorrect = hasAnswered && answer.isCorrect;
    final int correctIdx = question.correctAnswerIndex;

    Color badgeColor;
    String badgeText;
    IconData badgeIcon;

    if (!hasAnswered) {
      badgeColor = Colors.amber.shade700;
      badgeText = "Not Answered";
      badgeIcon = Icons.help_outline_rounded;
    } else if (isCorrect) {
      badgeColor = AppColors.successGreen;
      badgeText = "Correct";
      badgeIcon = Icons.check_circle_outline_rounded;
    } else {
      badgeColor = AppColors.heartRed;
      badgeText = "Wrong";
      badgeIcon = Icons.cancel_outlined;
    }

    final String selectedAnswerText = (selectedIdx >= 0 && selectedIdx < question.options.length)
        ? question.options[selectedIdx]
        : "Not Answered";

    final String correctAnswerText = (correctIdx >= 0 && correctIdx < question.options.length)
        ? question.options[correctIdx]
        : "";

    return GlassCard(
      padding: EdgeInsets.all(16.r),
      borderRadius: 20.r,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Header Row: Question Order & Result Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.softGold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: AppColors.softGold.withOpacity(0.4)),
                ),
                child: Text(
                  "Question ${index + 1}",
                  style: GoogleFonts.cairo(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.softGold,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: badgeColor.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    Icon(badgeIcon, size: 14.r, color: badgeColor),
                    SizedBox(width: 4.w),
                    Text(
                      badgeText,
                      style: GoogleFonts.cairo(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: badgeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 12.h),

          /// Question Text
          Text(
            question.questionText,
            style: GoogleFonts.cairo(
              fontSize: 15.sp,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),

          SizedBox(height: 14.h),

          /// Option Breakdown List
          ...List.generate(question.options.length, (optIdx) {
            final optionText = question.options[optIdx];
            final isUserSelection = optIdx == selectedIdx;
            final isCorrectOption = optIdx == correctIdx;

            Color optionBg;
            Color optionBorder;
            Color optionTextColor = textColor;
            Widget? trailingWidget;

            if (isUserSelection && isCorrectOption) {
              // User selected the correct answer
              optionBg = AppColors.successGreen.withOpacity(0.15);
              optionBorder = AppColors.successGreen;
              trailingWidget = Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: AppColors.successGreen,
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  "Your Answer ✓",
                  style: GoogleFonts.cairo(fontSize: 10.sp, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              );
            } else if (isUserSelection && !isCorrectOption) {
              // User selected wrong answer
              optionBg = AppColors.heartRed.withOpacity(0.15);
              optionBorder = AppColors.heartRed;
              trailingWidget = Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: AppColors.heartRed,
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  "Your Answer ❌",
                  style: GoogleFonts.cairo(fontSize: 10.sp, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              );
            } else if (isCorrectOption) {
              // Correct answer highlight
              optionBg = AppColors.successGreen.withOpacity(0.1);
              optionBorder = AppColors.successGreen.withOpacity(0.8);
              trailingWidget = Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: AppColors.successGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6.r),
                  border: Border.all(color: AppColors.successGreen),
                ),
                child: Text(
                  "Correct Answer ✓",
                  style: GoogleFonts.cairo(fontSize: 10.sp, fontWeight: FontWeight.bold, color: AppColors.successGreen),
                ),
              );
            } else {
              // Unselected normal option
              optionBg = isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03);
              optionBorder = borderColor.withOpacity(0.4);
            }

            final baseColor = _optionColors[optIdx % _optionColors.length];

            return Container(
              margin: EdgeInsets.only(bottom: 8.h),
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: optionBg,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: optionBorder, width: isUserSelection || isCorrectOption ? 1.5 : 1),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24.r,
                    height: 24.r,
                    decoration: BoxDecoration(
                      color: baseColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: baseColor, width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        String.fromCharCode(65 + optIdx), // A, B, C, D
                        style: GoogleFonts.cairo(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                          color: baseColor,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      optionText,
                      style: GoogleFonts.cairo(
                        fontSize: 13.sp,
                        fontWeight: isUserSelection || isCorrectOption ? FontWeight.bold : FontWeight.normal,
                        color: optionTextColor,
                      ),
                    ),
                  ),
                  if (trailingWidget != null) trailingWidget,
                ],
              ),
            );
          }),

          SizedBox(height: 8.h),

          /// Summary Box
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: isDark ? Colors.black.withOpacity(0.2) : Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: borderColor.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      "Your Answer: ",
                      style: GoogleFonts.cairo(fontSize: 12.sp, fontWeight: FontWeight.bold, color: mutedColor),
                    ),
                    Expanded(
                      child: Text(
                        selectedAnswerText,
                        style: GoogleFonts.cairo(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: isCorrect ? AppColors.successGreen : (hasAnswered ? AppColors.heartRed : Colors.amber.shade700),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Text(
                      "Correct Answer: ",
                      style: GoogleFonts.cairo(fontSize: 12.sp, fontWeight: FontWeight.bold, color: mutedColor),
                    ),
                    Expanded(
                      child: Text(
                        correctAnswerText,
                        style: GoogleFonts.cairo(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.successGreen,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
