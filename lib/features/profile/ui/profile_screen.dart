import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static final Map<String, String> examCache = {};

  /// 👤 name
  Future<String> getUserName() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .get();

    return doc.data()?["name"] ?? "Unknown";
  }

  /// 📊 user attempts
  Stream<QuerySnapshot> getUserAttempts() {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return FirebaseFirestore.instance
        .collection("examAttempts")
        .where("userId", isEqualTo: uid)
        .snapshots();
  }

  /// 📘 exam name
  Future<String> getExamName(String examId) async {
    if (examCache.containsKey(examId)) return examCache[examId]!;

    final doc = await FirebaseFirestore.instance
        .collection("exams")
        .doc(examId)
        .get();

    final name = doc.data()?["title"] ?? "Unknown Exam";
    examCache[examId] = name;

    return name;
  }

  /// 🔥 total score
  int getTotalScore(List<QueryDocumentSnapshot> docs) {
    int total = 0;
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      total += (data["score"] ?? 0) as int;
    }
    return total;
  }

  /// 🏆 REAL RANK
  Future<int> getUserRank(String uid) async {
    final snap = await FirebaseFirestore.instance
        .collection("examAttempts")
        .get();

    final Map<String, int> scores = {};

    for (var doc in snap.docs) {
      final data = doc.data();
      final userId = data["userId"];
      final score = (data["score"] ?? 0) as int;

      scores[userId] = (scores[userId] ?? 0) + score;
    }

    final list = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (int i = 0; i < list.length; i++) {
      if (list[i].key == uid) return i + 1;
    }

    return list.length;
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

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
        title: const Text("My Profile", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: getUserAttempts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(child: Lottie.asset("assets/lottie/not found.json"));
          }

          final totalScore = getTotalScore(docs);

          return FutureBuilder<String>(
            future: getUserName(),
            builder: (context, userSnap) {
              final name = userSnap.data ?? "Loading...";

              return FutureBuilder<int>(
                future: getUserRank(uid),
                builder: (context, rankSnap) {
                  final rank = rankSnap.data ?? 0;

                  return Column(
                    children: [
                      /// 🟦 HEADER
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          vertical: 25.h,
                          horizontal: 16.w,
                        ),
                        decoration: const BoxDecoration(
                          color: AppColors.primaryColor,
                        ),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 35.r,
                              backgroundColor: Colors.white,
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : "U",
                                style: TextStyle(
                                  fontSize: 22.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryColor,
                                ),
                              ),
                            ),

                            SizedBox(height: 10.h),

                            Text(
                              name,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            SizedBox(height: 12.h),

                            /// 📊 STATS (Responsive)
                            Wrap(
                              spacing: 12.w,
                              runSpacing: 10.h,
                              alignment: WrapAlignment.center,
                              children: [
                                _buildStat("Score", "$totalScore"),
                                _buildStat("Exams", "${docs.length}"),
                                _buildStat("Rank", "#$rank"),
                              ],
                            ),
                          ],
                        ),
                      ),

                      /// 📦 BODY
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(30.r),
                              topRight: Radius.circular(30.r),
                            ),
                          ),

                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "My Exams",
                                style: TextStyle(
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              SizedBox(height: 15.h),

                              Expanded(
                                child: ListView.separated(
                                  itemCount: docs.length,
                                  separatorBuilder: (_, __) =>
                                      SizedBox(height: 12.h),
                                  itemBuilder: (context, index) {
                                    final doc = docs[index];
                                    final data =
                                        doc.data() as Map<String, dynamic>;

                                    final examId = data["examId"];
                                    final score = data["score"] ?? 0;

                                    return FutureBuilder<String>(
                                      future: getExamName(examId),
                                      builder: (context, examSnap) {
                                        final examName =
                                            examSnap.data ?? "Loading...";

                                        return Container(
                                          padding: EdgeInsets.all(16.w),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              16.r,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.05,
                                                ),
                                                blurRadius: 10,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),

                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.book,
                                                color: AppColors.primaryColor,
                                              ),

                                              SizedBox(width: 10.w),

                                              Expanded(
                                                child: Text(
                                                  examName,
                                                  style: TextStyle(
                                                    fontSize: 15.sp,
                                                  ),
                                                ),
                                              ),

                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 12.w,
                                                  vertical: 6.h,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.green
                                                      .withOpacity(0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  "$score",
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
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  /// 📊 STAT WIDGET (Responsive)
  Widget _buildStat(String title, String value) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            title,
            style: TextStyle(color: Colors.white70, fontSize: 12.sp),
          ),
        ],
      ),
    );
  }
}
