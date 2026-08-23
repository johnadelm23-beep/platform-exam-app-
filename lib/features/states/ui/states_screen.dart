import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:platformexamapp/core/theme/app_colors.dart' show AppColors;
import 'package:platformexamapp/core/widgets/loading_state.dart';
import 'package:platformexamapp/features/states/ui/widgets/custom_bod_container.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  late final Stream<List<Map<String, dynamic>>> _leaderboardStream;

  @override
  void initState() {
    super.initState();
    _leaderboardStream = getLeaderboardStream();
  }

  Stream<List<Map<String, dynamic>>> getLeaderboardStream() {
    return FirebaseFirestore.instance
        .collection("examAttempts")
        .snapshots()
        .map((snap) {
          final Map<String, Map<String, dynamic>> users = {};

          for (var doc in snap.docs) {
            final data = doc.data();

            // Skip abandoned attempts
            if (data["abandoned"] == true) continue;

            final userId = data["userId"] as String?;
            if (userId == null || userId.isEmpty) continue;

            final scoreRaw = data["score"];
            final score = scoreRaw is num ? scoreRaw.toInt() : 0;
            final timestamp = data["timestamp"] as Timestamp? ?? data["createdAt"] as Timestamp?;

            if (!users.containsKey(userId)) {
              users[userId] = {
                "userId": userId,
                "totalScore": 0,
                "firstTime": timestamp,
              };
            }

            users[userId]!["totalScore"] = (users[userId]!["totalScore"] as int) + score;

            if (timestamp != null) {
              final old = users[userId]!["firstTime"] as Timestamp?;
              if (old == null || timestamp.compareTo(old) < 0) {
                users[userId]!["firstTime"] = timestamp;
              }
            }
          }

          final list = users.values.toList();

          list.sort((a, b) {
            final scoreA = (a["totalScore"] ?? 0) as int;
            final scoreB = (b["totalScore"] ?? 0) as int;

            // 1. Sort by total score descending
            if (scoreA != scoreB) {
              return scoreB.compareTo(scoreA);
            }

            // 2. Submission priority: Earlier submission timestamp ranks higher
            final timeA = a["firstTime"] as Timestamp?;
            final timeB = b["firstTime"] as Timestamp?;

            if (timeA != null && timeB != null) {
              final cmp = timeA.compareTo(timeB);
              if (cmp != 0) return cmp;
            } else if (timeA != null) {
              return -1;
            } else if (timeB != null) {
              return 1;
            }

            // 3. Deterministic fallback: userId comparison
            final idA = (a["userId"] ?? "").toString();
            final idB = (b["userId"] ?? "").toString();
            return idA.compareTo(idB);
          });

          return list;
        });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageBg = isDark ? AppColors.darkPageBg : AppColors.lightPageBg;
    final textColor = isDark ? AppColors.darkTextMain : AppColors.lightTextMain;

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: pageBg,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios, color: textColor, size: 20.r),
        ),
        centerTitle: true,
        title: Text(
          "top_players".tr(),
          style: GoogleFonts.cairo(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _leaderboardStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingState();
          }
          final data = snapshot.data ?? [];
          if (data.isEmpty) {
            return Center(child: Lottie.asset("assets/lottie/not found.json"));
          }
          final top3 = data.take(3).toList();
          final others = data.skip(3).toList();
          return CustomBodyContainer(top3: top3, others: others);
        },
      ),
    );
  }
}
