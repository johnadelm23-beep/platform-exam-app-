import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';
import 'package:platformexamapp/core/widgets/app_button.dart';
import 'package:platformexamapp/core/widgets/glass_card.dart';
import 'package:platformexamapp/core/widgets/loading_state.dart';
import 'package:platformexamapp/core/theme/app_page_route.dart';
import 'package:platformexamapp/features/games/data/models/game_model.dart';
import 'package:platformexamapp/features/games/data/services/game_service.dart';
import 'package:platformexamapp/features/games/ui/game_host_projector_screen.dart';

class GameHostControlScreen extends StatefulWidget {
  final String gameId;

  const GameHostControlScreen({
    super.key,
    required this.gameId,
  });

  @override
  State<GameHostControlScreen> createState() => _GameHostControlScreenState();
}

class _GameHostControlScreenState extends State<GameHostControlScreen> {
  late final Stream<DocumentSnapshot> _gameStream;
  late final Stream<QuerySnapshot> _teamsStream;
  late final Stream<QuerySnapshot> _questionsStream;

  @override
  void initState() {
    super.initState();
    _gameStream = FirebaseFirestore.instance.collection("games").doc(widget.gameId).snapshots();
    _teamsStream = FirebaseFirestore.instance.collection("games").doc(widget.gameId).collection("teams").orderBy("score", descending: true).snapshots();
    _questionsStream = FirebaseFirestore.instance.collection("games").doc(widget.gameId).collection("questions").orderBy("order").snapshots();
  }

  Future<void> _startGame() async {
    try {
      await GameService().startGame(widget.gameId);
    } catch (e) {
      _showSnackBar("Failed to start game: $e", isError: true);
    }
  }

  Future<void> _togglePauseResume(GameModel game) async {
    try {
      await GameService().togglePauseResume(game);
    } catch (e) {
      _showSnackBar("Failed to toggle pause/resume: $e", isError: true);
    }
  }

  Future<void> _endGame() async {
    try {
      await GameService().endGame(widget.gameId);
    } catch (e) {
      _showSnackBar("Failed to end game: $e", isError: true);
    }
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
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return StreamBuilder<DocumentSnapshot>(
      stream: _gameStream,
      builder: (context, gameSnap) {
        if (!gameSnap.hasData) return const Scaffold(body: LoadingState());
        final game = GameModel.fromSnapshot(gameSnap.data!);

        return Scaffold(
          backgroundColor: pageBg,
          body: SafeArea(
            child: Column(
              children: [
                /// App Bar Header
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
                            Icons.arrow_back_ios,
                            color: textColor,
                            size: 18.r,
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          "${"host_controls".tr()}: ${game.title}",
                          style: GoogleFonts.cairo(
                            fontSize: 18.sp,
                            color: textColor,
                            fontWeight: FontWeight.w900,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        tooltip: "Projector Mode",
                        icon: const Icon(Icons.tv_rounded, color: AppColors.softGold),
                        onPressed: () {
                          Navigator.push(
                            context,
                            AppPageRoute(child: GameHostProjectorScreen(gameId: widget.gameId)),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                /// Game Status & PIN Card
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: GlassCard(
                    padding: EdgeInsets.all(16.r),
                    borderRadius: 20.r,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "GAME PIN",
                              style: GoogleFonts.cairo(fontSize: 11.sp, color: mutedColor, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              game.pin,
                              style: GoogleFonts.cairo(
                                fontSize: 28.sp,
                                fontWeight: FontWeight.w900,
                                color: AppColors.softGold,
                                letterSpacing: 4,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            color: game.isPaused
                                ? AppColors.heartRed.withOpacity(0.15)
                                : AppColors.softGold.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(14.r),
                            border: Border.all(
                              color: game.isPaused ? AppColors.heartRed : AppColors.softGold,
                            ),
                          ),
                          child: Text(
                            game.isPaused ? "PAUSED" : game.status.toUpperCase(),
                            style: GoogleFonts.cairo(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                              color: game.isPaused ? AppColors.heartRed : AppColors.softGold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 14.h),

                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.r),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
                      border: Border(top: BorderSide(color: borderColor, width: 1)),
                    ),
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _questionsStream,
                      builder: (context, qSnap) {
                        final totalQCount = qSnap.hasData ? qSnap.data!.docs.length : 1;

                        return StreamBuilder<QuerySnapshot>(
                          stream: _teamsStream,
                          builder: (context, teamsSnap) {
                            final teamDocs = teamsSnap.data?.docs ?? [];

                            // Fetch answers for active question to show Answered Teams count
                            final answerDocPrefix = "q${game.currentQuestionIndex}_team_";

                            return StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection("games")
                                  .doc(widget.gameId)
                                  .collection("answers")
                                  .snapshots(),
                              builder: (context, answersSnap) {
                                final answersDocs = answersSnap.data?.docs ?? [];
                                final activeQuestionAnswers = answersDocs.where((d) => d.id.startsWith(answerDocPrefix)).toList();

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "live_teams".tr() + " (${teamDocs.length})",
                                          style: GoogleFonts.cairo(fontSize: 16.sp, fontWeight: FontWeight.bold, color: textColor),
                                        ),
                                        Text(
                                          "Question ${game.currentQuestionIndex + 1} / $totalQCount",
                                          style: GoogleFonts.cairo(fontSize: 13.sp, color: AppColors.softGold, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      "answered_teams".tr() + ": ${activeQuestionAnswers.length} / ${teamDocs.length}",
                                      style: GoogleFonts.cairo(fontSize: 12.sp, color: AppColors.successGreen, fontWeight: FontWeight.bold),
                                    ),

                                    SizedBox(height: 12.h),

                                    Expanded(
                                      child: teamDocs.isEmpty
                                          ? Center(
                                              child: Text("Waiting for teams to join with PIN: ${game.pin}", style: GoogleFonts.cairo(color: mutedColor)),
                                            )
                                          : ListView.separated(
                                              physics: const BouncingScrollPhysics(),
                                              itemCount: teamDocs.length,
                                              separatorBuilder: (_, __) => SizedBox(height: 8.h),
                                              itemBuilder: (context, index) {
                                                final team = GameTeamModel.fromSnapshot(teamDocs[index]);
                                                final hasAnswered = activeQuestionAnswers.any((a) => a.id.contains("team_${team.id}"));

                                                return GlassCard(
                                                  padding: EdgeInsets.all(12.r),
                                                  borderRadius: 14.r,
                                                  child: Row(
                                                    children: [
                                                      Text(team.emoji, style: TextStyle(fontSize: 22.sp)),
                                                      SizedBox(width: 10.w),
                                                      Expanded(
                                                        child: Text(
                                                          team.name,
                                                          style: GoogleFonts.cairo(fontSize: 14.sp, fontWeight: FontWeight.bold, color: textColor),
                                                        ),
                                                      ),
                                                      if (hasAnswered)
                                                        Container(
                                                          margin: EdgeInsets.only(right: 8.w),
                                                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                                                          decoration: BoxDecoration(
                                                            color: AppColors.successGreen.withOpacity(0.2),
                                                            borderRadius: BorderRadius.circular(8.r),
                                                          ),
                                                          child: Text(
                                                            "ANSWERED",
                                                            style: GoogleFonts.cairo(fontSize: 10.sp, fontWeight: FontWeight.bold, color: AppColors.successGreen),
                                                          ),
                                                        ),
                                                      Text(
                                                        "${team.score} pts",
                                                        style: GoogleFonts.cairo(fontSize: 14.sp, fontWeight: FontWeight.w900, color: AppColors.softGold),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
                                    ),

                                    SizedBox(height: 14.h),

                                    /// Simplified Host Minimal Control Buttons
                                    if (game.status == "lobby")
                                      AppButton(
                                        onPressed: teamDocs.isEmpty ? null : _startGame,
                                        text: "start_game".tr(),
                                      )
                                    else if (game.status != "finished")
                                      Row(
                                        children: [
                                          Expanded(
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: game.isPaused ? AppColors.successGreen : AppColors.softGold,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                                                minimumSize: Size(double.infinity, 48.h),
                                              ),
                                              onPressed: () => _togglePauseResume(game),
                                              child: Text(
                                                game.isPaused ? "resume_game".tr() : "pause_game".tr(),
                                                style: GoogleFonts.cairo(color: game.isPaused ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 10.w),
                                          Expanded(
                                            child: OutlinedButton(
                                              style: OutlinedButton.styleFrom(
                                                side: const BorderSide(color: AppColors.heartRed),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                                                minimumSize: Size(double.infinity, 48.h),
                                              ),
                                              onPressed: _endGame,
                                              child: Text(
                                                "end_game".tr(),
                                                style: GoogleFonts.cairo(color: AppColors.heartRed, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    else
                                      Text(
                                        "Game Finished 🎉",
                                        style: GoogleFonts.cairo(fontSize: 16.sp, fontWeight: FontWeight.bold, color: AppColors.successGreen),
                                        textAlign: TextAlign.center,
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
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
