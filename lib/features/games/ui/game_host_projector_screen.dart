import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';
import 'package:platformexamapp/core/widgets/app_button.dart';
import 'package:platformexamapp/core/widgets/empty_state.dart';
import 'package:platformexamapp/core/widgets/glass_card.dart';
import 'package:platformexamapp/core/widgets/loading_state.dart';
import 'package:platformexamapp/features/games/data/models/game_model.dart';
import 'package:platformexamapp/features/games/data/services/game_service.dart';
import 'package:platformexamapp/features/games/ui/widgets/live_authoritative_timer.dart';

class GameHostProjectorScreen extends StatefulWidget {
  final String gameId;

  const GameHostProjectorScreen({
    super.key,
    required this.gameId,
  });

  @override
  State<GameHostProjectorScreen> createState() => _GameHostProjectorScreenState();
}

class _GameHostProjectorScreenState extends State<GameHostProjectorScreen> {
  late final Stream<DocumentSnapshot> _gameStream;
  late final Stream<QuerySnapshot> _teamsStream;
  late final Stream<QuerySnapshot> _questionsStream;
  late final Stream<QuerySnapshot> _answersStream;

  Timer? _stateMachineTimer;
  Timer? _countdownTimer;

  int _secondsLeft = 15;
  bool _isTransitioning = false;

  final List<Color> _optionColors = const [
    Color(0xFF2563EB), // Blue
    Color(0xFFDC2626), // Red
    Color(0xFFD97706), // Yellow / Amber
    Color(0xFF16A34A), // Green
  ];

  @override
  void initState() {
    super.initState();
    _gameStream = FirebaseFirestore.instance.collection("games").doc(widget.gameId).snapshots();
    _teamsStream = FirebaseFirestore.instance.collection("games").doc(widget.gameId).collection("teams").orderBy("score", descending: true).snapshots();
    _questionsStream = FirebaseFirestore.instance.collection("games").doc(widget.gameId).collection("questions").orderBy("order").snapshots();
    _answersStream = FirebaseFirestore.instance.collection("games").doc(widget.gameId).collection("answers").snapshots();
  }

  @override
  void dispose() {
    _stateMachineTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
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
    } else {
      _secondsLeft = game.timePerQuestion;
    }

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (game.isPaused) return;

      final currentEndTime = game.questionEndTime?.toDate();
      if (currentEndTime != null) {
        final remaining = currentEndTime.difference(DateTime.now()).inSeconds;
        setState(() {
          _secondsLeft = remaining.clamp(0, game.timePerQuestion).toInt();
        });

        // Trigger Automated State Machine when timer reaches 0
        if (remaining <= 0 && game.status == "question_active" && game.autoProgress && !_isTransitioning) {
          _processAutomatedStateTransition(game);
        }
      }
    });
  }

  Future<void> _processAutomatedStateTransition(GameModel game) async {
    if (_isTransitioning) return;
    _isTransitioning = true;

    try {
      await GameService().processAutomatedStateTransition(game);
    } catch (_) {
    } finally {
      _isTransitioning = false;
    }
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

  Future<void> _toggleAutoProgress(GameModel game) async {
    try {
      await GameService().toggleAutoProgress(game);
    } catch (_) {}
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

        if (_countdownTimer == null || !_countdownTimer!.isActive) {
          _startLocalTimer(game);
        }

        return Scaffold(
          backgroundColor: pageBg,
          body: SafeArea(
            child: Column(
              children: [
                /// Large Screen Projector Top Header Bar
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: EdgeInsets.all(10.r),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.arrow_back_ios, color: textColor, size: 18.r),
                        ),
                      ),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: Text(
                          "📺 Live Projector Mode: ${game.title}",
                          style: GoogleFonts.cairo(
                            fontSize: 20.sp,
                            color: textColor,
                            fontWeight: FontWeight.w900,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              color: game.isPaused ? AppColors.heartRed.withOpacity(0.2) : AppColors.softGold.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(14.r),
                              border: Border.all(color: game.isPaused ? AppColors.heartRed : AppColors.softGold),
                            ),
                            child: Text(
                              "GAME PIN: ${game.pin} | ${game.isPaused ? 'PAUSED' : game.status.toUpperCase()}",
                              style: GoogleFonts.cairo(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w900,
                                color: game.isPaused ? AppColors.heartRed : AppColors.softGold,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                /// Main Projector Display Area
                Expanded(
                  child: Container(
                    width: double.infinity,
                    margin: EdgeInsets.symmetric(horizontal: 16.w),
                    padding: EdgeInsets.all(20.r),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(28.r),
                      border: Border.all(color: borderColor, width: 1),
                    ),
                    child: _buildProjectorBody(game, isDark, textColor, mutedColor, borderColor),
                  ),
                ),

                /// Host Floating Control Toolbar
                Padding(
                  padding: EdgeInsets.all(16.r),
                  child: Row(
                    children: [
                      if (game.status == "lobby")
                        Expanded(
                          child: AppButton(
                            onPressed: _startGame,
                            text: "start_game".tr() + " 🚀",
                          ),
                        )
                      else if (game.status != "finished") ...[
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: game.isPaused ? AppColors.successGreen : AppColors.softGold,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                              minimumSize: Size(double.infinity, 46.h),
                            ),
                            onPressed: () => _togglePauseResume(game),
                            child: Text(
                              game.isPaused ? "resume_game".tr() : "pause_game".tr(),
                              style: GoogleFonts.cairo(color: game.isPaused ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: game.autoProgress ? Colors.blueGrey : AppColors.softGold,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                            minimumSize: Size(130.w, 46.h),
                          ),
                          onPressed: () => _toggleAutoProgress(game),
                          child: Text(
                            game.autoProgress ? "Auto Mode ⚡" : "Manual Mode 👆",
                            style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.sp),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.heartRed),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                              minimumSize: Size(double.infinity, 46.h),
                            ),
                            onPressed: _endGame,
                            child: Text(
                              "end_game".tr(),
                              style: GoogleFonts.cairo(color: AppColors.heartRed, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ] else ...[
                        Expanded(
                          child: Text(
                            "Game Finished 🎉 — Host Control Session Closed",
                            style: GoogleFonts.cairo(fontSize: 16.sp, fontWeight: FontWeight.bold, color: AppColors.successGreen),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProjectorBody(GameModel game, bool isDark, Color textColor, Color mutedColor, Color borderColor) {
    if (game.status == "lobby") {
      return _buildLobbyProjectorView(game, isDark, textColor, mutedColor);
    }

    if (game.status == "question_leaderboard") {
      return _buildLeaderboardProjectorView(isDark, textColor);
    }

    if (game.status == "finished") {
      return _buildFinalPodiumProjectorView(isDark, textColor);
    }

    // Default: Active Question or Question Result View
    return StreamBuilder<QuerySnapshot>(
      stream: _questionsStream,
      builder: (context, qSnap) {
        if (!qSnap.hasData) return const LoadingState();
        final qDocs = qSnap.data!.docs;

        if (qDocs.isEmpty || game.currentQuestionIndex >= qDocs.length) {
          return const EmptyState(title: "No questions available", hugeIcon: HugeIcons.strokeRoundedGameController01);
        }

        final question = GameQuestionModel.fromSnapshot(qDocs[game.currentQuestionIndex]);

        return StreamBuilder<QuerySnapshot>(
          stream: _teamsStream,
          builder: (context, teamsSnap) {
            final teamDocs = teamsSnap.data?.docs ?? [];

            return StreamBuilder<QuerySnapshot>(
              stream: _answersStream,
              builder: (context, answersSnap) {
                final answerDocs = answersSnap.data?.docs ?? [];
                final answerPrefix = "q${game.currentQuestionIndex}_team_";
                final activeAnswers = answerDocs.where((d) => d.id.startsWith(answerPrefix)).toList();

                return Column(
                  children: [
                    /// Projector Question Progress & Countdown Timer Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              "Question ${game.currentQuestionIndex + 1} / ${qDocs.length}",
                              style: GoogleFonts.cairo(fontSize: 20.sp, fontWeight: FontWeight.w900, color: AppColors.softGold),
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        LiveAuthoritativeTimer(
                          endTime: game.questionEndTime?.toDate() ?? DateTime.now().add(Duration(seconds: game.timePerQuestion)),
                          totalSeconds: game.timePerQuestion,
                          isPaused: game.isPaused,
                          onTimeUp: () {
                            if (game.status == "question_active" && game.autoProgress) {
                              _processAutomatedStateTransition(game);
                            }
                          },
                        ),
                        SizedBox(width: 8.w),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              "Answered: ${activeAnswers.length} / ${teamDocs.length} Teams",
                              style: GoogleFonts.cairo(fontSize: 16.sp, fontWeight: FontWeight.bold, color: AppColors.successGreen),
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 16.h),

                    /// Large Projector Question Text Card
                    GlassCard(
                      padding: EdgeInsets.all(24.r),
                      borderRadius: 24.r,
                      child: Center(
                        child: Text(
                          question.questionText,
                          style: GoogleFonts.cairo(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.w900,
                            color: textColor,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),

                    SizedBox(height: 20.h),

                    /// 4 Projector Color-Coded Choice Cards
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14.w,
                        mainAxisSpacing: 14.h,
                        childAspectRatio: 2.2,
                        children: List.generate(question.options.length, (optIdx) {
                          final color = _optionColors[optIdx % _optionColors.length];
                          final isCorrectAnswer = (game.status == "question_result" && optIdx == question.correctAnswerIndex);

                          return Container(
                            padding: EdgeInsets.all(16.r),
                            decoration: BoxDecoration(
                              color: isCorrectAnswer ? AppColors.successGreen : color,
                              borderRadius: BorderRadius.circular(20.r),
                              border: Border.all(
                                color: isCorrectAnswer ? Colors.white : Colors.transparent,
                                width: isCorrectAnswer ? 4 : 0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withOpacity(0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18.r,
                                  backgroundColor: Colors.white.withOpacity(0.2),
                                  child: Text(
                                    String.fromCharCode(65 + optIdx), // A, B, C, D
                                    style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16.sp),
                                  ),
                                ),
                                SizedBox(width: 14.w),
                                Expanded(
                                  child: Text(
                                    question.options[optIdx],
                                    style: GoogleFonts.cairo(
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                if (isCorrectAnswer)
                                  const Icon(Icons.check_circle, color: Colors.white, size: 28),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),

                    SizedBox(height: 12.h),

                    /// Active Teams Response Chips Status Bar
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: teamDocs.map((tDoc) {
                          final team = GameTeamModel.fromSnapshot(tDoc);
                          final hasAnswered = activeAnswers.any((a) => a.id.contains("team_${team.id}"));

                          return Container(
                            margin: EdgeInsets.only(right: 8.w),
                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              color: hasAnswered ? AppColors.successGreen.withOpacity(0.2) : Colors.grey.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: hasAnswered ? AppColors.successGreen : Colors.grey.shade400,
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(hasAnswered ? "🟢" : "⚪", style: TextStyle(fontSize: 12.sp)),
                                SizedBox(width: 6.w),
                                Text(team.emoji, style: TextStyle(fontSize: 14.sp)),
                                SizedBox(width: 4.w),
                                Text(
                                  team.name,
                                  style: GoogleFonts.cairo(fontSize: 12.sp, fontWeight: FontWeight.bold, color: textColor),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildLobbyProjectorView(GameModel game, bool isDark, Color textColor, Color mutedColor) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "JOIN GAME WITH PIN",
          style: GoogleFonts.cairo(fontSize: 18.sp, color: mutedColor, fontWeight: FontWeight.bold, letterSpacing: 4),
        ),
        SizedBox(height: 8.h),
        Text(
          game.pin,
          style: GoogleFonts.cairo(
            fontSize: 64.sp,
            fontWeight: FontWeight.w900,
            color: AppColors.softGold,
            letterSpacing: 10,
          ),
        ),
        SizedBox(height: 20.h),
        StreamBuilder<QuerySnapshot>(
          stream: _teamsStream,
          builder: (context, teamsSnap) {
            final teamDocs = teamsSnap.data?.docs ?? [];
            return Column(
              children: [
                Text(
                  "Connected Teams (${teamDocs.length} / ${game.maxTeams})",
                  style: GoogleFonts.cairo(fontSize: 18.sp, fontWeight: FontWeight.bold, color: textColor),
                ),
                SizedBox(height: 16.h),
                Wrap(
                  spacing: 12.w,
                  runSpacing: 12.h,
                  children: teamDocs.map((doc) {
                    final team = GameTeamModel.fromSnapshot(doc);
                    return GlassCard(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                      borderRadius: 16.r,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(team.emoji, style: TextStyle(fontSize: 24.sp)),
                          SizedBox(width: 8.w),
                          Text(
                            team.name,
                            style: GoogleFonts.cairo(fontSize: 16.sp, fontWeight: FontWeight.bold, color: textColor),
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            "(${team.memberCount} members)",
                            style: GoogleFonts.cairo(fontSize: 12.sp, color: AppColors.softGold),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildLeaderboardProjectorView(bool isDark, Color textColor) {
    return StreamBuilder<QuerySnapshot>(
      stream: _teamsStream,
      builder: (context, teamsSnap) {
        final teamDocs = teamsSnap.data?.docs ?? [];
        final teams = teamDocs
            .map((d) => GameTeamModel.fromSnapshot(d))
            .where((t) => t.isParticipating)
            .toList()
          ..sort((a, b) => b.score.compareTo(a.score));

        debugPrint("[LEADERBOARD] Source = CURRENT_GAME_TEAMS");
        debugPrint("[LEADERBOARD] currentGameId = ${widget.gameId}");
        debugPrint("[LEADERBOARD] Firestore teams count = ${teamDocs.length}");
        debugPrint("[LEADERBOARD] Participating teams count = ${teams.length}");
        debugPrint("[LEADERBOARD] Ranked teams = ${teams.map((t) => '${t.emoji} ${t.name} (${t.score} pts)').join(', ')}");

        if (teams.isEmpty) {
          return EmptyState(
            title: "No connected teams",
            hugeIcon: HugeIcons.strokeRoundedUserGroup,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "🏆 LIVE TEAM STANDINGS",
              style: GoogleFonts.cairo(fontSize: 24.sp, fontWeight: FontWeight.w900, color: AppColors.softGold),
            ),
            SizedBox(height: 16.h),
            Expanded(
              child: ListView.separated(
                itemCount: teams.length,
                separatorBuilder: (_, __) => SizedBox(height: 10.h),
                itemBuilder: (context, index) {
                  final team = teams[index];
                  final rank = index + 1;

                  return GlassCard(
                    padding: EdgeInsets.all(16.r),
                    borderRadius: 18.r,
                    child: Row(
                      children: [
                        Text(
                          rank == 1 ? "🥇" : (rank == 2 ? "🥈" : (rank == 3 ? "🥉" : "#$rank")),
                          style: TextStyle(fontSize: 22.sp),
                        ),
                        SizedBox(width: 14.w),
                        Text(team.emoji, style: TextStyle(fontSize: 26.sp)),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            team.name,
                            style: GoogleFonts.cairo(fontSize: 20.sp, fontWeight: FontWeight.bold, color: textColor),
                          ),
                        ),
                        Text(
                          "${team.score} pts",
                          style: GoogleFonts.cairo(fontSize: 22.sp, fontWeight: FontWeight.w900, color: AppColors.softGold),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFinalPodiumProjectorView(bool isDark, Color textColor) {
    return StreamBuilder<QuerySnapshot>(
      stream: _teamsStream,
      builder: (context, teamsSnap) {
        final teamDocs = teamsSnap.data?.docs ?? [];
        final teams = teamDocs
            .map((d) => GameTeamModel.fromSnapshot(d))
            .where((t) => t.isParticipating)
            .toList()
          ..sort((a, b) => b.score.compareTo(a.score));

        final winner = teams.isNotEmpty ? teams[0] : null;
        final second = teams.length > 1 ? teams[1] : null;
        final third = teams.length > 2 ? teams[2] : null;

        return Column(
          children: [
            Text(
              "🎉 GAME FINISHED — FINAL TEAM PODIUM 🎉",
              style: GoogleFonts.cairo(fontSize: 22.sp, fontWeight: FontWeight.w900, color: AppColors.softGold),
            ),
            SizedBox(height: 20.h),
            Expanded(
              child: GlassCard(
                padding: EdgeInsets.all(20.r),
                borderRadius: 28.r,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (second != null) _buildPodiumStep(second, "🥈", 120.h, AppColors.goldDark, textColor),
                    if (winner != null) _buildPodiumStep(winner, "🥇", 160.h, AppColors.softGold, textColor),
                    if (third != null) _buildPodiumStep(third, "🥉", 90.h, Colors.brown.shade400, textColor),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPodiumStep(GameTeamModel team, String badge, double height, Color color, Color textColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(badge, style: TextStyle(fontSize: 28.sp)),
        Text(team.emoji, style: TextStyle(fontSize: 26.sp)),
        SizedBox(height: 4.h),
        Text(
          team.name,
          style: GoogleFonts.cairo(fontSize: 14.sp, fontWeight: FontWeight.bold, color: textColor),
        ),
        SizedBox(height: 6.h),
        Container(
          width: 90.w,
          height: height,
          decoration: BoxDecoration(
            color: color.withOpacity(0.25),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: Text(
              "${team.score}\npts",
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(fontSize: 16.sp, fontWeight: FontWeight.w900, color: color),
            ),
          ),
        ),
      ],
    );
  }
}
