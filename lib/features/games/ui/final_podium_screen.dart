import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';
import 'package:platformexamapp/core/widgets/empty_state.dart';
import 'package:platformexamapp/core/widgets/glass_card.dart';
import 'package:platformexamapp/core/theme/app_page_route.dart';
import 'package:platformexamapp/core/widgets/loading_state.dart';
import 'package:platformexamapp/features/games/data/models/game_model.dart';
import 'package:platformexamapp/features/games/ui/game_answer_review_screen.dart';

class FinalPodiumScreen extends StatefulWidget {
  final String gameId;

  const FinalPodiumScreen({
    super.key,
    required this.gameId,
  });

  @override
  State<FinalPodiumScreen> createState() => _FinalPodiumScreenState();
}

class _FinalPodiumScreenState extends State<FinalPodiumScreen> {
  late final Stream<DocumentSnapshot> _gameStream;
  late final Stream<QuerySnapshot> _teamsStream;

  @override
  void initState() {
    super.initState();
    _gameStream = FirebaseFirestore.instance.collection("games").doc(widget.gameId).snapshots();
    _teamsStream = FirebaseFirestore.instance.collection("games").doc(widget.gameId).collection("teams").orderBy("score", descending: true).snapshots();
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

        return Scaffold(
          backgroundColor: pageBg,
          body: SafeArea(
            child: StreamBuilder<QuerySnapshot>(
              stream: _teamsStream,
              builder: (context, teamsSnap) {
                final teamDocs = teamsSnap.data?.docs ?? [];
                if (teamDocs.isEmpty) {
                  return EmptyState(
                    title: "No game results found",
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
                    title: "No game results found",
                    hugeIcon: HugeIcons.strokeRoundedAward01,
                  );
                }

                final winner = teams.isNotEmpty ? teams[0] : null;
                final second = teams.length > 1 ? teams[1] : null;
                final third = teams.length > 2 ? teams[2] : null;

                return Column(
                  children: [
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
                          Text(
                            "final_results".tr(),
                            style: GoogleFonts.cairo(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.w900,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ),

                    /// Animated Final Team Podium
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: GlassCard(
                        padding: EdgeInsets.all(20.r),
                        borderRadius: 28.r,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            /// 2nd Place Podium
                            if (second != null) _buildPodiumStep(second, "🥈", 100.h, AppColors.goldDark, textColor),
                            /// 1st Place Winner Podium
                            if (winner != null) _buildPodiumStep(winner, "🥇", 130.h, AppColors.softGold, textColor),
                            /// 3rd Place Podium
                            if (third != null) _buildPodiumStep(third, "🥉", 80.h, Colors.brown.shade400, textColor),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Final Team Standings",
                              style: GoogleFonts.cairo(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            SizedBox(height: 10.h),
                            Expanded(
                              child: ListView.separated(
                                physics: const BouncingScrollPhysics(),
                                itemCount: teams.length,
                                separatorBuilder: (_, __) => SizedBox(height: 8.h),
                                itemBuilder: (context, index) {
                                  final t = teams[index];
                                  return GlassCard(
                                    padding: EdgeInsets.all(12.r),
                                    borderRadius: 14.r,
                                    child: Row(
                                      children: [
                                        Text(
                                          "#${index + 1}",
                                          style: GoogleFonts.cairo(
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.softGold,
                                          ),
                                        ),
                                        SizedBox(width: 10.w),
                                        Text(t.emoji, style: TextStyle(fontSize: 20.sp)),
                                        SizedBox(width: 8.w),
                                        Expanded(
                                          child: Text(
                                            t.name,
                                            style: GoogleFonts.cairo(
                                              fontSize: 15.sp,
                                              fontWeight: FontWeight.bold,
                                              color: textColor,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          "${t.score} pts",
                                          style: GoogleFonts.cairo(
                                            fontSize: 15.sp,
                                            fontWeight: FontWeight.w900,
                                            color: AppColors.softGold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            SizedBox(height: 14.h),
                            SizedBox(
                              width: double.infinity,
                              height: 52.h,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.softGold,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                                  elevation: 2,
                                ),
                                icon: const Icon(Icons.assignment_outlined, color: Colors.black87),
                                label: Text(
                                  "Review Answers",
                                  style: GoogleFonts.cairo(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    AppPageRoute(
                                      child: GameAnswerReviewScreen(gameId: widget.gameId),
                                    ),
                                  );
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
            ),
          ),
        );
      },
    );
  }

  Widget _buildPodiumStep(GameTeamModel team, String badge, double height, Color color, Color textColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(badge, style: TextStyle(fontSize: 24.sp)),
        Text(team.emoji, style: TextStyle(fontSize: 22.sp)),
        SizedBox(height: 4.h),
        Text(
          team.name,
          style: GoogleFonts.cairo(fontSize: 12.sp, fontWeight: FontWeight.bold, color: textColor),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 4.h),
        Container(
          width: 70.w,
          height: height,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
            border: Border.all(color: color),
          ),
          child: Center(
            child: Text(
              "${team.score}\npts",
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(fontSize: 12.sp, fontWeight: FontWeight.w900, color: color),
            ),
          ),
        ),
      ],
    );
  }
}
