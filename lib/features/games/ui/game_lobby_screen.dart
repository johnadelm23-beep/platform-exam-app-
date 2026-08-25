import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';
import 'package:platformexamapp/core/theme/app_page_route.dart';
import 'package:platformexamapp/core/widgets/app_button.dart';
import 'package:platformexamapp/core/widgets/empty_state.dart';
import 'package:platformexamapp/core/widgets/glass_card.dart';
import 'package:platformexamapp/core/widgets/loading_state.dart';
import 'package:platformexamapp/features/games/data/models/game_model.dart';
import 'package:platformexamapp/features/games/data/services/game_service.dart';
import 'package:platformexamapp/features/games/ui/game_play_screen.dart';

class GameLobbyScreen extends StatefulWidget {
  final String gameId;
  final bool isHost;

  const GameLobbyScreen({
    super.key,
    required this.gameId,
    this.isHost = false,
  });

  @override
  State<GameLobbyScreen> createState() => _GameLobbyScreenState();
}

class _GameLobbyScreenState extends State<GameLobbyScreen> {
  late final Stream<DocumentSnapshot> _gameStream;
  late final Stream<QuerySnapshot> _teamsStream;

  @override
  void initState() {
    super.initState();
    _gameStream = FirebaseFirestore.instance.collection("games").doc(widget.gameId).snapshots();
    _teamsStream = FirebaseFirestore.instance.collection("games").doc(widget.gameId).collection("teams").snapshots();
  }

  Future<void> _startGame() async {
    try {
      await GameService().startGame(widget.gameId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to start game: $e", style: GoogleFonts.cairo()),
            backgroundColor: AppColors.heartRed,
          ),
        );
      }
    }
  }

  void _handleGameStatusChange(GameModel game) {
    if (game.status == "question_active" || game.status == "paused") {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          AppPageRoute(
            child: GamePlayScreen(gameId: widget.gameId),
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
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return StreamBuilder<DocumentSnapshot>(
      stream: _gameStream,
      builder: (context, gameSnap) {
        if (!gameSnap.hasData) return const Scaffold(body: LoadingState());
        final game = GameModel.fromSnapshot(gameSnap.data!);

        _handleGameStatusChange(game);

        return Scaffold(
          backgroundColor: pageBg,
          body: SafeArea(
            child: Column(
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
                            Icons.arrow_back_ios,
                            color: textColor,
                            size: 18.r,
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          game.title,
                          style: GoogleFonts.cairo(
                            fontSize: 18.sp,
                            color: textColor,
                            fontWeight: FontWeight.w900,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                /// PIN Display Banner
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: GlassCard(
                    padding: EdgeInsets.all(18.r),
                    borderRadius: 20.r,
                    child: Column(
                      children: [
                        Text(
                          "GAME PIN",
                          style: GoogleFonts.cairo(
                            fontSize: 12.sp,
                            color: mutedColor,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          game.pin,
                          style: GoogleFonts.cairo(
                            fontSize: 34.sp,
                            fontWeight: FontWeight.w900,
                            color: AppColors.softGold,
                            letterSpacing: 6,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          "joined_lobby".tr(),
                          style: GoogleFonts.cairo(fontSize: 12.sp, color: AppColors.successGreen),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 16.h),

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
                            title: "Waiting for teams to join with PIN: ${game.pin}",
                            hugeIcon: HugeIcons.strokeRoundedUserGroup,
                          );
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "${"teams".tr()} (${teamDocs.length})",
                                  style: GoogleFonts.cairo(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                                Text(
                                  "Max per team: ${game.maxMembersPerTeam}",
                                  style: GoogleFonts.cairo(fontSize: 12.sp, color: AppColors.softGold),
                                ),
                              ],
                            ),
                            SizedBox(height: 12.h),

                            Expanded(
                              child: ListView.separated(
                                physics: const BouncingScrollPhysics(),
                                itemCount: teamDocs.length,
                                separatorBuilder: (_, __) => SizedBox(height: 10.h),
                                itemBuilder: (context, index) {
                                  final team = GameTeamModel.fromSnapshot(teamDocs[index]);

                                  return GlassCard(
                                    padding: EdgeInsets.all(14.r),
                                    borderRadius: 16.r,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(team.emoji, style: TextStyle(fontSize: 24.sp)),
                                            SizedBox(width: 10.w),
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
                                            Container(
                                              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                                              decoration: BoxDecoration(
                                                color: AppColors.softGold.withOpacity(0.15),
                                                borderRadius: BorderRadius.circular(12.r),
                                              ),
                                              child: Text(
                                                "${team.memberCount} members",
                                                style: GoogleFonts.cairo(
                                                  fontSize: 12.sp,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.softGold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),

                                        /// Stream Members for Team Roster
                                        StreamBuilder<QuerySnapshot>(
                                          stream: FirebaseFirestore.instance
                                              .collection("games")
                                              .doc(widget.gameId)
                                              .collection("teams")
                                              .doc(team.id)
                                              .collection("members")
                                              .snapshots(),
                                          builder: (context, memberSnap) {
                                            final members = memberSnap.data?.docs.map((d) => GameTeamMemberModel.fromSnapshot(d)).toList() ?? [];
                                            if (members.isEmpty) return const SizedBox.shrink();

                                            return Padding(
                                              padding: EdgeInsets.only(top: 8.h),
                                              child: Wrap(
                                                spacing: 6.w,
                                                runSpacing: 4.h,
                                                children: members.map((m) {
                                                  return Chip(
                                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                    padding: EdgeInsets.zero,
                                                    backgroundColor: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
                                                    label: Text(
                                                      m.displayName,
                                                      style: GoogleFonts.cairo(fontSize: 11.sp, color: textColor),
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),

                            if (widget.isHost) ...[
                              SizedBox(height: 12.h),
                              AppButton(
                                onPressed: teamDocs.isEmpty ? null : _startGame,
                                text: "start_game".tr(),
                              ),
                            ],
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
  }
}
