import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';
import 'package:platformexamapp/core/theme/app_page_route.dart';
import 'package:platformexamapp/core/widgets/empty_state.dart';
import 'package:platformexamapp/core/widgets/glass_card.dart';
import 'package:platformexamapp/core/widgets/loading_state.dart';
import 'package:platformexamapp/features/games/data/models/game_model.dart';
import 'package:platformexamapp/features/games/ui/final_podium_screen.dart';
import 'package:platformexamapp/features/games/ui/game_play_screen.dart';

class LiveLeaderboardScreen extends StatefulWidget {
  final String gameId;

  const LiveLeaderboardScreen({
    super.key,
    required this.gameId,
  });

  @override
  State<LiveLeaderboardScreen> createState() => _LiveLeaderboardScreenState();
}

class _LiveLeaderboardScreenState extends State<LiveLeaderboardScreen> {
  late final Stream<DocumentSnapshot> _gameStream;
  late final Stream<QuerySnapshot> _teamsStream;

  @override
  void initState() {
    super.initState();
    _gameStream = FirebaseFirestore.instance.collection("games").doc(widget.gameId).snapshots();
    _teamsStream = FirebaseFirestore.instance.collection("games").doc(widget.gameId).collection("teams").orderBy("score", descending: true).snapshots();
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
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return StreamBuilder<DocumentSnapshot>(
      stream: _gameStream,
      builder: (context, gameSnap) {
        if (!gameSnap.hasData) return const Scaffold(body: LoadingState());
        final game = GameModel.fromSnapshot(gameSnap.data!);

        _handleGameStatusTransitions(game);

        return Scaffold(
          backgroundColor: pageBg,
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(20.r),
                  child: Text(
                    "live_leaderboard".tr(),
                    style: GoogleFonts.cairo(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                    ),
                  ),
                ),
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
                      stream: _teamsStream,
                      builder: (context, teamsSnap) {
                        final teamDocs = teamsSnap.data?.docs ?? [];
                        if (teamDocs.isEmpty) {
                          return EmptyState(
                            title: "No team records found",
                            hugeIcon: HugeIcons.strokeRoundedAward01,
                          );
                        }

                        final teams = teamDocs
                            .map((d) => GameTeamModel.fromSnapshot(d))
                            .where((t) => t.isParticipating)
                            .toList()
                          ..sort((a, b) => b.score.compareTo(a.score));

                        if (teams.isEmpty) {
                          return EmptyState(
                            title: "No team records found",
                            hugeIcon: HugeIcons.strokeRoundedAward01,
                          );
                        }

                        return ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          itemCount: teams.length,
                          separatorBuilder: (_, __) => SizedBox(height: 10.h),
                          itemBuilder: (context, index) {
                            final team = teams[index];
                            final rank = index + 1;

                            return GlassCard(
                              padding: EdgeInsets.all(14.r),
                              borderRadius: 16.r,
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(8.r),
                                    decoration: BoxDecoration(
                                      color: rank == 1
                                          ? AppColors.softGold.withOpacity(0.2)
                                          : (rank == 2 ? Colors.grey.withOpacity(0.2) : Colors.orange.withOpacity(0.15)),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      rank == 1 ? "🥇" : (rank == 2 ? "🥈" : (rank == 3 ? "🥉" : "#$rank")),
                                      style: TextStyle(fontSize: 16.sp),
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  Text(team.emoji, style: TextStyle(fontSize: 22.sp)),
                                  SizedBox(width: 8.w),
                                  Expanded(
                                    child: Text(
                                      team.name,
                                      style: GoogleFonts.cairo(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    "${team.score} pts",
                                    style: GoogleFonts.cairo(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.softGold,
                                    ),
                                  ),
                                ],
                              ),
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
