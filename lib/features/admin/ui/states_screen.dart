import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:platformexamapp/core/widgets/app_dialog.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';
import 'package:platformexamapp/core/widgets/empty_state.dart';
import 'package:platformexamapp/core/widgets/glass_card.dart';
import 'package:platformexamapp/core/widgets/loading_state.dart';
import 'package:platformexamapp/features/auth/data/models/user_data.dart';

class UserAttemptItem {
  final String docId;
  final String examId;
  final String examTitle;
  final int score;
  final Timestamp? timestamp;
  final bool isDeletedExam;

  UserAttemptItem({
    required this.docId,
    required this.examId,
    required this.examTitle,
    required this.score,
    this.timestamp,
    required this.isDeletedExam,
  });
}

class UserLeaderboardData {
  final String userId;
  final String userName;
  final int totalPoints;
  final int examsCompleted;
  final Timestamp? earliestTimestamp;
  final List<UserAttemptItem> attempts;

  UserLeaderboardData({
    required this.userId,
    required this.userName,
    required this.totalPoints,
    required this.examsCompleted,
    this.earliestTimestamp,
    required this.attempts,
  });
}

class ScoresStatisticsScreen extends StatefulWidget {
  const ScoresStatisticsScreen({super.key, this.user});
  final UserData? user;

  @override
  State<ScoresStatisticsScreen> createState() => _ScoresStatisticsScreenState();
}

class _ScoresStatisticsScreenState extends State<ScoresStatisticsScreen> {
  late final Stream<List<UserLeaderboardData>> _leaderboardStream;
  final Set<String> _expandedUserIds = {};

  @override
  void initState() {
    super.initState();
    _leaderboardStream = _getLeaderboardStream();
  }

  Stream<List<UserLeaderboardData>> _getLeaderboardStream() {
    return FirebaseFirestore.instance
        .collection("examAttempts")
        .snapshots()
        .asyncMap((attemptsSnap) async {
      // 1. Fetch active exams map
      final examsSnap =
          await FirebaseFirestore.instance.collection("exams").get();
      final Map<String, String> activeExams = {};
      for (var doc in examsSnap.docs) {
        final data = doc.data();
        if (data.containsKey("title")) {
          activeExams[doc.id] = (data["title"] as String?) ?? "";
        }
      }

      // 2. Fetch users map
      final usersSnap =
          await FirebaseFirestore.instance.collection("users").get();
      final Map<String, String> userNames = {};
      for (var doc in usersSnap.docs) {
        final data = doc.data();
        if (data.containsKey("name")) {
          userNames[doc.id] = (data["name"] as String?) ?? "";
        }
      }

      // 3. Process attempts and group by userId
      final Map<String, List<UserAttemptItem>> userAttemptsMap = {};
      final Map<String, Timestamp?> userEarliestTimestampMap = {};

      for (var doc in attemptsSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;

        final abandoned = data["abandoned"] == true;
        if (abandoned) continue;

        final userId = data["userId"] as String?;
        if (userId == null || userId.isEmpty) continue;

        final scoreRaw = data["score"];
        if (scoreRaw == null) continue;
        final score = (scoreRaw as num).toInt();

        final examId = (data["examId"] as String?) ?? "";
        final storedTitle = data["examTitle"] as String?;
        final timestamp =
            data["timestamp"] as Timestamp? ?? data["createdAt"] as Timestamp?;

        String resolvedTitle = "";
        bool isDeletedExam = false;

        if (activeExams.containsKey(examId) &&
            activeExams[examId]!.isNotEmpty) {
          resolvedTitle = activeExams[examId]!;
        } else if (storedTitle != null && storedTitle.isNotEmpty) {
          resolvedTitle = storedTitle;
          isDeletedExam = true;
        } else {
          // Orphaned attempt without active exam document and without snapshot title.
          // Safely skip so "Unknown Exam" never corrupts UI or stats.
          continue;
        }

        final attemptItem = UserAttemptItem(
          docId: doc.id,
          examId: examId,
          examTitle: resolvedTitle,
          score: score,
          timestamp: timestamp,
          isDeletedExam: isDeletedExam,
        );

        if (!userAttemptsMap.containsKey(userId)) {
          userAttemptsMap[userId] = [];
        }
        userAttemptsMap[userId]!.add(attemptItem);

        if (timestamp != null) {
          final existingEarliest = userEarliestTimestampMap[userId];
          if (existingEarliest == null ||
              timestamp.compareTo(existingEarliest) < 0) {
            userEarliestTimestampMap[userId] = timestamp;
          }
        }
      }

      // 4. Build UserLeaderboardData list
      final List<UserLeaderboardData> result = [];
      userAttemptsMap.forEach((userId, attempts) {
        final fetchedName = userNames[userId];
        final userName = (fetchedName != null && fetchedName.isNotEmpty)
            ? fetchedName
            : "User ${userId.length > 5 ? userId.substring(0, 5) : userId}";
        final totalPoints =
            attempts.fold<int>(0, (sum, item) => sum + item.score);
        final examsCompleted = attempts.length;
        final earliestTimestamp = userEarliestTimestampMap[userId];

        result.add(
          UserLeaderboardData(
            userId: userId,
            userName: userName,
            totalPoints: totalPoints,
            examsCompleted: examsCompleted,
            earliestTimestamp: earliestTimestamp,
            attempts: attempts,
          ),
        );
      });

      // 5. Sort users: totalPoints DESC, tie-breaker earliestTimestamp ASC, userName ASC
      result.sort((a, b) {
        if (a.totalPoints != b.totalPoints) {
          return b.totalPoints.compareTo(a.totalPoints);
        }
        if (a.earliestTimestamp != null && b.earliestTimestamp != null) {
          final cmp = a.earliestTimestamp!.compareTo(b.earliestTimestamp!);
          if (cmp != 0) return cmp;
        } else if (a.earliestTimestamp != null) {
          return -1;
        } else if (b.earliestTimestamp != null) {
          return 1;
        }
        return a.userName.compareTo(b.userName);
      });

      return result;
    });
  }

  Future<void> deleteAttempt(BuildContext context, String docId) async {
    await FirebaseFirestore.instance
        .collection("examAttempts")
        .doc(docId)
        .delete();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Deleted successfully", style: GoogleFonts.cairo()),
          backgroundColor: AppColors.successGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void showDeleteAttemptDialog({
    required BuildContext context,
    required VoidCallback onDelete,
  }) {
    AppDialog.show(
      context: context,
      iconWidget: HugeIcon(
        icon: HugeIcons.strokeRoundedDelete01,
        color: AppColors.heartRed,
        size: 36.r,
      ),
      iconColor: AppColors.heartRed,
      title: "Delete Result?",
      description:
          "Are you sure you want to delete this exam result? This action cannot be undone.",
      confirmText: "Delete",
      confirmButtonColor: AppColors.heartRed,
      cancelText: "Cancel",
      onConfirm: () {
        Navigator.pop(context);
        onDelete();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageBg = isDark ? AppColors.darkPageBg : AppColors.lightPageBg;
    final textColor = isDark ? AppColors.darkTextMain : AppColors.lightTextMain;
    final surfaceColor =
        isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final mutedColor =
        isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

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
                    "Top Grades 🏆",
                    style: GoogleFonts.cairo(
                      fontSize: 22.sp,
                      color: textColor,
                      fontWeight: FontWeight.bold,
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
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32.r),
                    topRight: Radius.circular(32.r),
                  ),
                  border: Border(top: BorderSide(color: borderColor, width: 1)),
                ),
                child: StreamBuilder<List<UserLeaderboardData>>(
                  stream: _leaderboardStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          "Error loading data",
                          style: GoogleFonts.cairo(color: AppColors.heartRed),
                        ),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const LoadingState();
                    }

                    final leaderboard = snapshot.data ?? [];

                    if (leaderboard.isEmpty) {
                      return EmptyState(
                        title: "No Scores Recorded",
                        hugeIcon: HugeIcons.strokeRoundedAnalytics01,
                      );
                    }

                    return ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      itemCount: leaderboard.length,
                      separatorBuilder: (_, __) => SizedBox(height: 12.h),
                      itemBuilder: (context, index) {
                        final userData = leaderboard[index];
                        final isExpanded =
                            _expandedUserIds.contains(userData.userId);

                        return _buildUserCard(
                          context: context,
                          userData: userData,
                          rank: index + 1,
                          isExpanded: isExpanded,
                          onToggleExpand: () {
                            setState(() {
                              if (isExpanded) {
                                _expandedUserIds.remove(userData.userId);
                              } else {
                                _expandedUserIds.add(userData.userId);
                              }
                            });
                          },
                          isDark: isDark,
                          textColor: textColor,
                          mutedColor: mutedColor,
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

  Widget _buildUserCard({
    required BuildContext context,
    required UserLeaderboardData userData,
    required int rank,
    required bool isExpanded,
    required VoidCallback onToggleExpand,
    required bool isDark,
    required Color textColor,
    required Color mutedColor,
  }) {
    return GlassCard(
      padding: EdgeInsets.all(14.r),
      borderRadius: 18.r,
      child: Column(
        children: [
          InkWell(
            onTap: onToggleExpand,
            borderRadius: BorderRadius.circular(14.r),
            child: Row(
              children: [
                // Rank Badge
                Container(
                  width: 42.r,
                  height: 42.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.softGold.withOpacity(0.15),
                    border: Border.all(
                      color: AppColors.softGold.withOpacity(0.4),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      "#$rank",
                      style: GoogleFonts.cairo(
                        color: AppColors.softGold,
                        fontWeight: FontWeight.bold,
                        fontSize: 15.sp,
                      ),
                    ),
                  ),
                ),

                SizedBox(width: 12.w),

                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userData.userName,
                        style: GoogleFonts.cairo(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        userData.examsCompleted == 1
                            ? "1 Exam"
                            : "${userData.examsCompleted} Exams",
                        style: GoogleFonts.cairo(
                          color: mutedColor,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ),

                // Total Points Badge
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.successGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppColors.successGreen.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    "${userData.totalPoints} pts",
                    style: GoogleFonts.cairo(
                      color: AppColors.successGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                    ),
                  ),
                ),

                SizedBox(width: 8.w),

                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: mutedColor,
                  size: 22.r,
                ),
              ],
            ),
          ),

          // Exam Score Breakdown List
          if (isExpanded) ...[
            SizedBox(height: 12.h),
            Divider(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.1),
            ),
            SizedBox(height: 6.h),
            ...userData.attempts.map((attempt) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 6.h),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(6.r),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.softGold.withOpacity(0.1),
                      ),
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedFile01,
                        color: AppColors.softGold,
                        size: 16.r,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            attempt.examTitle,
                            style: GoogleFonts.cairo(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          if (attempt.isDeletedExam)
                            Text(
                              "Deleted Exam",
                              style: GoogleFonts.cairo(
                                fontSize: 10.sp,
                                color: AppColors.heartRed.withOpacity(0.8),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 3.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.successGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        "${attempt.score} pts",
                        style: GoogleFonts.cairo(
                          color: AppColors.successGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                    if (widget.user?.isAdminVal == true ||
                        widget.user?.canAccessGradeStates == true) ...[
                      SizedBox(width: 4.w),
                      IconButton(
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.all(6.r),
                        icon: const HugeIcon(
                          icon: HugeIcons.strokeRoundedDelete01,
                          color: AppColors.heartRed,
                        ),
                        onPressed: () {
                          showDeleteAttemptDialog(
                            context: context,
                            onDelete: () async {
                              await deleteAttempt(context, attempt.docId);
                            },
                          );
                        },
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
