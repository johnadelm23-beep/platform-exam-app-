import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';
import 'package:platformexamapp/core/theme/app_page_route.dart';
import 'package:platformexamapp/core/widgets/app_dialog.dart';
import 'package:platformexamapp/core/widgets/empty_state.dart';
import 'package:platformexamapp/core/widgets/glass_card.dart';
import 'package:platformexamapp/core/widgets/loading_state.dart';
import 'package:platformexamapp/features/admin/ui/add_game_screen.dart';
import 'package:platformexamapp/features/admin/ui/game_host_control_screen.dart';
import 'package:platformexamapp/features/auth/data/models/user_data.dart';
import 'package:platformexamapp/features/games/data/models/game_model.dart';
import 'package:platformexamapp/features/games/data/services/game_service.dart';
import 'package:platformexamapp/features/games/ui/game_host_projector_screen.dart';

class AdminGamesScreen extends StatefulWidget {
  const AdminGamesScreen({super.key, required this.user});
  final UserData user;

  @override
  State<AdminGamesScreen> createState() => _AdminGamesScreenState();
}

class _AdminGamesScreenState extends State<AdminGamesScreen> {
  late final Stream<QuerySnapshot> _gamesStream;

  @override
  void initState() {
    super.initState();
    _gamesStream = FirebaseFirestore.instance.collection("games").snapshots();
  }

  String _generateGamePin() {
    final rng = Random();
    final pinNum = 100000 + rng.nextInt(900000);
    return pinNum.toString();
  }

  Future<void> _launchLiveSession(GameModel game) async {
    try {
      await GameService().launchLiveLobby(game.id);

      if (!mounted) return;

      Navigator.push(
        context,
        AppPageRoute(
          child: GameHostProjectorScreen(gameId: game.id),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to launch live session: $e", style: GoogleFonts.cairo()),
            backgroundColor: AppColors.heartRed,
          ),
        );
      }
    }
  }

  void _deleteGame(String gameId) {
    AppDialog.show(
      context: context,
      iconWidget: HugeIcon(
        icon: HugeIcons.strokeRoundedDelete01,
        color: AppColors.heartRed,
        size: 36.r,
      ),
      iconColor: AppColors.heartRed,
      title: "delete".tr(),
      description: "Are you sure you want to delete this game?",
      confirmText: "delete".tr(),
      confirmButtonColor: AppColors.heartRed,
      cancelText: "cancel".tr(),
      onConfirm: () async {
        Navigator.pop(context);
        await FirebaseFirestore.instance.collection("games").doc(gameId).delete();
      },
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
                  Expanded(
                    child: Text(
                      "games_management".tr(),
                      style: GoogleFonts.cairo(
                        fontSize: 20.sp,
                        color: textColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
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
                  SizedBox(width: 8.w),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        AppPageRoute(child: const AddGameScreen()),
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.all(10.r),
                      decoration: const BoxDecoration(
                        color: AppColors.softGold,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add,
                        color: Colors.black87,
                        size: 18.r,
                      ),
                    ),
                  ),
                ],
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
                  stream: _gamesStream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const LoadingState();
                    final docs = snapshot.data!.docs;

                    if (docs.isEmpty) {
                      return EmptyState(
                        title: "no_games_found".tr(),
                        hugeIcon: HugeIcons.strokeRoundedGameController01,
                      );
                    }

                    return ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => SizedBox(height: 12.h),
                      itemBuilder: (context, index) {
                        final game = GameModel.fromSnapshot(docs[index]);
                        final bool isLive = game.status != "draft" && game.status != "finished";

                        return GlassCard(
                          padding: EdgeInsets.all(16.r),
                          borderRadius: 20.r,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(10.r),
                                    decoration: BoxDecoration(
                                      color: AppColors.softGold.withOpacity(0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: HugeIcon(
                                      icon: HugeIcons.strokeRoundedGameController01,
                                      color: AppColors.softGold,
                                      size: 24.r,
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
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
                                          "Status: ${game.status.toUpperCase()} ${game.pin.isNotEmpty ? '| PIN: ${game.pin}' : ''}",
                                          style: GoogleFonts.cairo(
                                            fontSize: 12.sp,
                                            color: isLive ? AppColors.successGreen : mutedColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => _deleteGame(game.id),
                                    icon: const HugeIcon(
                                      icon: HugeIcons.strokeRoundedDelete01,
                                      color: AppColors.softRed,
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: 12.h),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "${game.timePerQuestion}s per question",
                                    style: GoogleFonts.cairo(fontSize: 12.sp, color: mutedColor),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isLive ? AppColors.successGreen : AppColors.softGold,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                                      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                                    ),
                                    onPressed: () {
                                      if (isLive) {
                                        Navigator.push(
                                          context,
                                          AppPageRoute(
                                            child: GameHostProjectorScreen(gameId: game.id),
                                          ),
                                        );
                                      } else {
                                        _launchLiveSession(game);
                                      }
                                    },
                                    child: Text(
                                      isLive ? "Open Live Session" : "Launch Session 🚀",
                                      style: GoogleFonts.cairo(
                                        color: isLive ? Colors.white : Colors.black87,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12.sp,
                                      ),
                                    ),
                                  ),
                                ],
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
  }
}
