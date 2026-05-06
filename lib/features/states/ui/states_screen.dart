import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  Future<String> getUserName(String userId) async {
    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .get();

    return doc.data()?["name"] ?? "Unknown";
  }

  Stream<List<Map<String, dynamic>>> getLeaderboardStream() {
    return FirebaseFirestore.instance
        .collection("examAttempts")
        .snapshots()
        .map((snap) {
          final Map<String, Map<String, dynamic>> users = {};

          for (var doc in snap.docs) {
            final data = doc.data();

            final userId = data["userId"];
            final score = (data["score"] ?? 0) as int;
            final createdAt = data["createdAt"] as Timestamp?;

            if (!users.containsKey(userId)) {
              users[userId] = {
                "userId": userId,
                "totalScore": 0,
                "firstTime": createdAt,
              };
            }

            users[userId]!["totalScore"] += score;

            if (createdAt != null) {
              final old = users[userId]!["firstTime"] as Timestamp?;
              if (old == null || createdAt.compareTo(old) < 0) {
                users[userId]!["firstTime"] = createdAt;
              }
            }
          }

          final list = users.values.toList();

          list.sort((a, b) {
            final scoreA = a["totalScore"] as int;
            final scoreB = b["totalScore"] as int;

            if (scoreA != scoreB) {
              return scoreB.compareTo(scoreA);
            }

            final timeA = a["firstTime"] as Timestamp?;
            final timeB = b["firstTime"] as Timestamp?;

            if (timeA == null || timeB == null) return 0;

            return timeA.compareTo(timeB);
          });

          return list;
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor,

      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back_ios, color: AppColors.whiteColor),
        ),
        centerTitle: true,
        title: const Text(
          "Top players 🏆",
          style: TextStyle(color: Colors.white),
        ),
      ),

      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: getLeaderboardStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          final data = snapshot.data ?? [];

          if (data.isEmpty) {
            return Center(child: Lottie.asset("assets/lottie/not found.json"));
          }

          final top3 = data.take(3).toList();
          final others = data.skip(3).toList();

          return Container(
            padding: EdgeInsets.all(16.r),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),

            child: Column(
              children: [
                SizedBox(height: 10.h),

                SizedBox(
                  height: 210.h,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (top3.length > 1) _podium(top3[1], 2, Colors.grey),
                      if (top3.isNotEmpty) _podium(top3[0], 1, Colors.amber),
                      if (top3.length > 2)
                        _podium(top3[2], 3, AppColors.primaryColor),
                    ],
                  ),
                ),

                const Divider(),

                Expanded(
                  child: ListView.separated(
                    itemCount: others.length,
                    separatorBuilder: (_, __) => SizedBox(height: 10.h),
                    itemBuilder: (context, index) {
                      final user = others[index];

                      return FutureBuilder<String>(
                        future: getUserName(user["userId"]),
                        builder: (context, snap) {
                          final name = snap.data ?? "...";

                          return Container(
                            padding: EdgeInsets.all(16.r),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(color: Colors.blue.shade100),
                            ),

                            child: Row(
                              children: [
                                Text(
                                  "#${index + 4}",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),

                                SizedBox(width: 12.w),

                                Expanded(
                                  child: Text(
                                    name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),

                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12.w,
                                    vertical: 6.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    "${user["totalScore"]}",
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
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
              ],
            ),
          );
        },
      ),
    );
  }

  /// 🏆 PODIUM (consistent style)
  Widget _podium(Map<String, dynamic> user, int rank, Color color) {
    return FutureBuilder<String>(
      future: getUserName(user["userId"]),
      builder: (context, snap) {
        final name = snap.data ?? "...";

        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            CircleAvatar(
              radius: rank == 1 ? 34 : 28,
              backgroundColor: color,
              child: Text("$rank", style: const TextStyle(color: Colors.white)),
            ),

            SizedBox(height: 8),

            Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),

            SizedBox(height: 4),

            Text(
              "${user["totalScore"]}",
              style: const TextStyle(color: Colors.green),
            ),

            SizedBox(height: 10),

            Container(
              width: 70,
              height: rank == 1 ? 160 : 120,
              decoration: BoxDecoration(
                color: color.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ],
        );
      },
    );
  }
}
