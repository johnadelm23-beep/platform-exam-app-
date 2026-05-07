import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';
import 'package:platformexamapp/features/profile/ui/widgets/custom_app_bar_profile.dart';
import 'package:platformexamapp/features/profile/ui/widgets/custom_body_container.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  Future<String> getUserName() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .get();

    return doc.data()?["name"] ?? "Unknown";
  }

  Stream<QuerySnapshot> getUserAttempts() {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return FirebaseFirestore.instance
        .collection("examAttempts")
        .where("userId", isEqualTo: uid)
        .snapshots();
  }

  int getTotalScore(List<QueryDocumentSnapshot> docs) {
    int total = 0;
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      total += (data["score"] ?? 0) as int;
    }
    return total;
  }

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
                      CustomAppBarProfile(
                        name: name,
                        totalScore: totalScore,
                        docs: docs,
                        rank: rank,
                      ),
                      Expanded(child: CustomBodyContainer(docs: docs)),
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
}
