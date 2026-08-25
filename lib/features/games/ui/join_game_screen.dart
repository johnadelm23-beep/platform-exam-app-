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
import 'package:platformexamapp/core/widgets/custom_text_form_field.dart';
import 'package:platformexamapp/core/widgets/glass_card.dart';
import 'package:platformexamapp/features/auth/data/models/user_data.dart';
import 'package:platformexamapp/features/games/data/models/game_model.dart';
import 'package:platformexamapp/features/games/data/services/game_service.dart';
import 'package:platformexamapp/features/games/ui/game_host_projector_screen.dart';
import 'package:platformexamapp/features/games/ui/game_lobby_screen.dart';

class JoinGameScreen extends StatefulWidget {
  const JoinGameScreen({super.key});

  @override
  State<JoinGameScreen> createState() => _JoinGameScreenState();
}

class _JoinGameScreenState extends State<JoinGameScreen> {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _teamNameController = TextEditingController();

  bool _isLoading = false;
  GameModel? _foundGame;

  String _selectedEmoji = "🦁";
  String _selectedTeamId = "";
  List<GameTeamModel> _existingTeams = [];

  final List<String> _emojiPalette = const [
    "🦁", "🐯", "🐼", "🦊", "🚀", "⭐",
    "🔥", "⚡", "🏆", "🎯", "😎", "😀",
  ];

  Future<void> _validatePinAndFindGame() async {
    final pin = _pinController.text.trim();
    if (pin.isEmpty || pin.length < 4) {
      _showSnackBar("invalid_pin".tr(), isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw "User not logged in";

      // Query active game matching PIN
      final querySnap = await FirebaseFirestore.instance
          .collection("games")
          .where("pin", isEqualTo: pin)
          .where("status", whereIn: ["lobby", "question_active", "question_result", "question_leaderboard", "paused"])
          .limit(1)
          .get();

      if (querySnap.docs.isEmpty) {
        throw "invalid_pin".tr();
      }

      final gameDoc = querySnap.docs.first;
      final game = GameModel.fromSnapshot(gameDoc);

      // If user is the Host / Creator of this game, open Projector Mode directly
      if (game.createdBy == user.uid) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          AppPageRoute(
            child: GameHostProjectorScreen(gameId: game.id),
          ),
        );
        return;
      }

      // Check if user is ALREADY in a team for this game
      final userTeamDoc = await gameDoc.reference.collection("userTeams").doc(user.uid).get();
      if (userTeamDoc.exists) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          AppPageRoute(
            child: GameLobbyScreen(
              gameId: game.id,
              isHost: false,
            ),
          ),
        );
        return;
      }

      // Fetch existing teams
      final teamsSnap = await gameDoc.reference.collection("teams").get();
      final teams = teamsSnap.docs.map((doc) => GameTeamModel.fromSnapshot(doc)).toList();

      setState(() {
        _foundGame = game;
        _existingTeams = teams;
        if (_existingTeams.isNotEmpty) {
          _selectedTeamId = _existingTeams.first.id;
          _selectedEmoji = _existingTeams.first.emoji;
          _teamNameController.text = _existingTeams.first.name;
        } else {
          _selectedTeamId = "team_1";
          _teamNameController.text = "";
        }
      });
    } catch (e) {
      if (mounted) {
        _showSnackBar(e.toString().replaceAll("Exception:", "").trim(), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _joinSelectedTeam() async {
    if (_foundGame == null) return;

    final teamName = _teamNameController.text.trim();
    if (teamName.isEmpty) {
      _showSnackBar("team_name_hint".tr(), isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw "User not logged in";

      final userDoc = await FirebaseFirestore.instance.collection("users").doc(user.uid).get();
      final userData = UserData.fromJson(userDoc.data() ?? {}, user.uid);

      await GameService().joinTeam(
        gameId: _foundGame!.id,
        selectedTeamId: _selectedTeamId,
        teamName: teamName,
        teamEmoji: _selectedEmoji,
        user: userData,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        AppPageRoute(
          child: GameLobbyScreen(
            gameId: _foundGame!.id,
            isHost: false,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        _showSnackBar(e.toString().replaceAll("Exception:", "").trim(), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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

    return Scaffold(
      backgroundColor: pageBg,
      body: SafeArea(
        child: Column(
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
                    "join_game".tr(),
                    style: GoogleFonts.cairo(
                      fontSize: 22.sp,
                      color: textColor,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(20.r),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
                  border: Border(top: BorderSide(color: borderColor, width: 1)),
                ),
                child: _foundGame == null
                    ? _buildPinInputStep(textColor)
                    : _buildTeamSelectionStep(isDark, textColor, borderColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPinInputStep(Color textColor) {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 20.h),
          GlassCard(
            padding: EdgeInsets.all(24.r),
            borderRadius: 24.r,
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: AppColors.softGold.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedGameController01,
                    color: AppColors.softGold,
                    size: 48.r,
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  "enter_game_pin".tr(),
                  style: GoogleFonts.cairo(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24.h),
                CustomTextFormField(
                  hintText: "game_pin_hint".tr(),
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 24.h),
                AppButton(
                  onPressed: _isLoading ? null : _validatePinAndFindGame,
                  text: _isLoading ? "Validating PIN..." : "Next",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamSelectionStep(bool isDark, Color textColor, Color borderColor) {
    final game = _foundGame!;
    final availableTeamSlots = List.generate(game.maxTeams, (i) => "team_${i + 1}");

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "choose_your_team".tr(),
            style: GoogleFonts.cairo(
              fontSize: 20.sp,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            "Game: ${game.title} (PIN: ${game.pin})",
            style: GoogleFonts.cairo(fontSize: 13.sp, color: AppColors.softGold, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16.h),

          /// Teams Choice Cards
          Wrap(
            spacing: 10.w,
            runSpacing: 10.h,
            children: availableTeamSlots.map((tId) {
              final existing = _existingTeams.firstWhere(
                (t) => t.id == tId,
                orElse: () => GameTeamModel(
                  id: tId,
                  name: "Team ${tId.replaceAll('team_', '')}",
                  emoji: "🦁",
                  score: 0,
                  rank: 0,
                  memberCount: 0,
                  maxMembers: game.maxMembersPerTeam,
                  isParticipating: false,
                ),
              );

              final isSelected = (_selectedTeamId == tId);
              final isFull = (existing.memberCount >= game.maxMembersPerTeam);

              return GestureDetector(
                onTap: isFull
                    ? null
                    : () {
                        setState(() {
                          _selectedTeamId = tId;
                          _selectedEmoji = existing.emoji;
                          if (existing.memberCount > 0) {
                            _teamNameController.text = existing.name;
                          }
                        });
                      },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.softGold.withOpacity(0.2)
                        : (isFull ? Colors.grey.withOpacity(0.1) : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04))),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: isSelected ? AppColors.softGold : borderColor,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(existing.emoji, style: TextStyle(fontSize: 20.sp)),
                      SizedBox(width: 8.w),
                      Text(
                        existing.name,
                        style: GoogleFonts.cairo(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: isFull ? Colors.grey : textColor,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: isFull ? AppColors.heartRed.withOpacity(0.2) : AppColors.softGold.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Text(
                          "${existing.memberCount}/${game.maxMembersPerTeam}",
                          style: GoogleFonts.cairo(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                            color: isFull ? AppColors.heartRed : AppColors.softGold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          SizedBox(height: 24.h),

          /// Emoji & Team Name Customization Card
          Text(
            "select_team_emoji".tr(),
            style: GoogleFonts.cairo(fontSize: 16.sp, fontWeight: FontWeight.bold, color: textColor),
          ),
          SizedBox(height: 10.h),
          GlassCard(
            padding: EdgeInsets.all(16.r),
            borderRadius: 20.r,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Emoji Selector Palette
                Wrap(
                  spacing: 12.w,
                  runSpacing: 10.h,
                  children: _emojiPalette.map((emoji) {
                    final isEmojiSelected = (_selectedEmoji == emoji);
                    return GestureDetector(
                      onTap: () => setState(() => _selectedEmoji = emoji),
                      child: Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isEmojiSelected ? AppColors.softGold.withOpacity(0.3) : Colors.transparent,
                          border: Border.all(
                            color: isEmojiSelected ? AppColors.softGold : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Text(emoji, style: TextStyle(fontSize: 24.sp)),
                      ),
                    );
                  }).toList(),
                ),

                SizedBox(height: 16.h),

                CustomTextFormField(
                  hintText: "team_name_hint".tr(),
                  controller: _teamNameController,
                ),
              ],
            ),
          ),

          SizedBox(height: 24.h),

          AppButton(
            onPressed: _isLoading ? null : _joinSelectedTeam,
            text: _isLoading ? "Joining Team..." : "join_game".tr(),
          ),

          SizedBox(height: 20.h),
        ],
      ),
    );
  }
}
