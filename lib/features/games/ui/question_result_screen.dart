import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';
import 'package:platformexamapp/core/theme/app_page_route.dart';
import 'package:platformexamapp/core/widgets/glass_card.dart';
import 'package:platformexamapp/core/widgets/loading_state.dart';
import 'package:platformexamapp/features/games/data/models/game_model.dart';
import 'package:platformexamapp/features/games/ui/final_podium_screen.dart';
import 'package:platformexamapp/features/games/ui/game_play_screen.dart';
import 'package:platformexamapp/features/games/ui/live_leaderboard_screen.dart';

class QuestionResultScreen extends StatefulWidget {
  final String gameId;
  final int questionIndex;
  final String teamId;

  const QuestionResultScreen({
    super.key,
    required this.gameId,
    required this.questionIndex,
    required this.teamId,
  });

  @override
  State<QuestionResultScreen> createState() => _QuestionResultScreenState();
}

class _QuestionResultScreenState extends State<QuestionResultScreen> {
  late final Stream<DocumentSnapshot> _gameStream;
  late final Stream<DocumentSnapshot> _answerStream;
  late final Stream<DocumentSnapshot> _teamStream;

  @override
  void initState() {
    super.initState();
    _gameStream = FirebaseFirestore.instance.collection("games").doc(widget.gameId).snapshots();
    _answerStream = FirebaseFirestore.instance
        .collection("games")
        .doc(widget.gameId)
        .collection("answers")
        .doc("q${widget.questionIndex}_team_${widget.teamId}")
        .snapshots();
    _teamStream = FirebaseFirestore.instance
        .collection("games")
        .doc(widget.gameId)
        .collection("teams")
        .doc(widget.teamId)
        .snapshots();
  }

  void _handleGameStatusTransitions(GameModel game) {
    if (game.status == "question_active") {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          AppPageRoute(
            child: GamePlayScreen(gameId: widget.gameId),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageBg = isDark ? AppColors.darkPageBg : AppColors.lightPageBg;
    final textColor = isDark ? AppColors.darkTextMain : AppColors.lightTextMain;

    return StreamBuilder<DocumentSnapshot>(
      stream: _gameStream,
      builder: (context, gameSnap) {
        if (!gameSnap.hasData) return const Scaffold(body: LoadingState());
        final game = GameModel.fromSnapshot(gameSnap.data!);

        _handleGameStatusTransitions(game);

        return Scaffold(
          backgroundColor: pageBg,
          body: SafeArea(
            child: StreamBuilder<DocumentSnapshot>(
              stream: _answerStream,
              builder: (context, answerSnap) {
                final hasAnswer = answerSnap.data?.exists ?? false;
                final answerData = hasAnswer ? (answerSnap.data!.data() as Map<String, dynamic>?) : null;

                final bool isCorrect = answerData?["isCorrect"] as bool? ?? false;
                final int pointsEarned = (answerData?["pointsEarned"] as num?)?.toInt() ?? 0;

                return StreamBuilder<DocumentSnapshot>(
                  stream: _teamStream,
                  builder: (context, teamSnap) {
                    final team = teamSnap.hasData ? GameTeamModel.fromSnapshot(teamSnap.data!) : null;

                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.r),
                        child: GlassCard(
                          padding: EdgeInsets.all(24.r),
                          borderRadius: 28.r,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (team != null) ...[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(team.emoji, style: TextStyle(fontSize: 28.sp)),
                                    SizedBox(width: 8.w),
                                    Text(
                                      team.name,
                                      style: GoogleFonts.cairo(
                                        fontSize: 20.sp,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.softGold,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16.h),
                              ],

                              Container(
                                padding: EdgeInsets.all(20.r),
                                decoration: BoxDecoration(
                                  color: (hasAnswer && isCorrect)
                                      ? AppColors.successGreen.withOpacity(0.15)
                                      : AppColors.heartRed.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  (hasAnswer && isCorrect) ? Icons.check_circle : Icons.cancel,
                                  color: (hasAnswer && isCorrect) ? AppColors.successGreen : AppColors.heartRed,
                                  size: 64.r,
                                ),
                              ),

                              SizedBox(height: 16.h),

                              Text(
                                !hasAnswer
                                    ? "No Team Answer Submitted"
                                    : (isCorrect ? "correct_answer".tr() : "wrong_answer".tr()),
                                style: GoogleFonts.cairo(
                                  fontSize: 22.sp,
                                  fontWeight: FontWeight.w900,
                                  color: (hasAnswer && isCorrect) ? AppColors.successGreen : AppColors.heartRed,
                                ),
                                textAlign: TextAlign.center,
                              ),

                              SizedBox(height: 12.h),

                              Text(
                                "points_earned".tr(args: ["$pointsEarned"]),
                                style: GoogleFonts.cairo(
                                  fontSize: 28.sp,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.softGold,
                                ),
                              ),

                              if (team != null) ...[
                                SizedBox(height: 16.h),
                                Text(
                                  "total_points".tr(args: ["${team.score}"]),
                                  style: GoogleFonts.cairo(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}
