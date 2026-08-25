import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
import 'package:platformexamapp/features/games/ui/game_lobby_screen.dart';
import 'package:platformexamapp/features/games/ui/join_game_screen.dart';

class GamesHomeScreen extends StatefulWidget {
  const GamesHomeScreen({super.key});

  @override
  State<GamesHomeScreen> createState() => _GamesHomeScreenState();
}

class _GamesHomeScreenState extends State<GamesHomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Stream<QuerySnapshot> _gamesStream;

  String? _activeGameId;
  String? _activeTeamName;
  String? _activeTeamEmoji;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _gamesStream = FirebaseFirestore.instance.collection("games").snapshots();
    _checkActiveUserSession();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkActiveUserSession() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final sessionData = await GameService().checkActiveUserSession(user.uid);
      if (sessionData != null && mounted) {
        setState(() {
          _activeGameId = sessionData["gameId"];
          _activeTeamName = sessionData["teamName"];
          _activeTeamEmoji = sessionData["teamEmoji"];
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageBg = isDark ? AppColors.darkPageBg : AppColors.lightPageBg;
    final textColor = isDark ? AppColors.darkTextMain : AppColors.lightTextMain;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

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
                  Text(
                    "games".tr(),
                    style: GoogleFonts.cairo(
                      fontSize: 22.sp,
                      color: textColor,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),

            /// Active Session Rejoin Card
            if (_activeGameId != null) ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: GlassCard(
                  padding: EdgeInsets.all(16.r),
                  borderRadius: 20.r,
                  child: Row(
                    children: [
                      Text(_activeTeamEmoji ?? "🦁", style: TextStyle(fontSize: 28.sp)),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Active Game Session",
                              style: GoogleFonts.cairo(fontSize: 12.sp, color: AppColors.softGold, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              _activeTeamName ?? "Team",
                              style: GoogleFonts.cairo(fontSize: 16.sp, fontWeight: FontWeight.bold, color: textColor),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.softGold,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            AppPageRoute(
                              child: GameLobbyScreen(
                                gameId: _activeGameId!,
                                isHost: false,
                              ),
                            ),
                          );
                        },
                        child: Text(
                          "rejoin_game".tr(),
                          style: GoogleFonts.cairo(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 12.sp),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 14.h),
            ],

            /// PIN Join Hero Action Card
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: GlassCard(
                padding: EdgeInsets.all(18.r),
                borderRadius: 24.r,
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(14.r),
                      decoration: BoxDecoration(
                        color: AppColors.softGold.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedGameController01,
                        color: AppColors.softGold,
                        size: 32.r,
                      ),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Have a Game PIN?",
                            style: GoogleFonts.cairo(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          Text(
                            "Join live team session instantly",
                            style: GoogleFonts.cairo(
                              fontSize: 12.sp,
                              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.softGold,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          AppPageRoute(child: const JoinGameScreen()),
                        );
                      },
                      child: Text(
                        "join_game".tr(),
                        style: GoogleFonts.cairo(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16.h),

            /// Tabs Header
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16.w),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppColors.softGold,
                  borderRadius: BorderRadius.circular(14.r),
                ),
                labelColor: Colors.black87,
                unselectedLabelColor: textColor,
                labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13.sp),
                tabs: const [
                  Tab(text: "Live Sessions"),
                  Tab(text: "Finished Games"),
                ],
              ),
            ),

            SizedBox(height: 12.h),

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
                  stream: _gamesStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}", style: GoogleFonts.cairo(color: AppColors.heartRed)));
                    if (!snapshot.hasData && snapshot.connectionState == ConnectionState.waiting) return const LoadingState();

                    final docs = snapshot.data?.docs ?? [];
                    final allGames = docs.map((d) => GameModel.fromSnapshot(d)).toList();

                    final liveGames = allGames.where((g) => g.status != "draft" && g.status != "finished").toList();
                    final finishedGames = allGames.where((g) => g.status == "finished").toList();

                    return TabBarView(
                      controller: _tabController,
                      children: [
                        _buildGamesList(liveGames, isLive: true, isDark: isDark, textColor: textColor),
                        _buildGamesList(finishedGames, isLive: false, isDark: isDark, textColor: textColor),
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
  }

  Widget _buildGamesList(List<GameModel> games, {required bool isLive, required bool isDark, required Color textColor}) {
    if (games.isEmpty) {
      return EmptyState(
        title: "no_games_found".tr(),
        hugeIcon: HugeIcons.strokeRoundedGameController01,
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      itemCount: games.length,
      separatorBuilder: (_, __) => SizedBox(height: 10.h),
      itemBuilder: (context, index) {
        final game = games[index];

        return GlassCard(
          padding: EdgeInsets.all(16.r),
          borderRadius: 20.r,
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: isLive ? AppColors.successGreen.withOpacity(0.15) : AppColors.softGold.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedGameController01,
                  color: isLive ? AppColors.successGreen : AppColors.softGold,
                  size: 24.r,
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.title,
                      style: GoogleFonts.cairo(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    Text(
                      isLive ? "PIN: ${game.pin} | Live Session 🔴" : "Finished 🎉",
                      style: GoogleFonts.cairo(
                        fontSize: 12.sp,
                        color: isLive ? AppColors.successGreen : AppColors.softGold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isLive ? AppColors.successGreen : AppColors.softGold,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    AppPageRoute(
                      child: GameLobbyScreen(
                        gameId: game.id,
                        isHost: false,
                      ),
                    ),
                  );
                },
                child: Text(
                  isLive ? "Join" : "Results",
                  style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
