import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconly/iconly.dart';
import 'package:lottie/lottie.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';

class ScoresStatisticsScreen extends StatelessWidget {
  const ScoresStatisticsScreen({super.key});

  static final Map<String, String> examCache = {};

  Future<String> getUserName(String userId) async {
    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .get();

    if (doc.exists) {
      return doc.data()?["name"] ?? "Unknown";
    }
    return "Unknown";
  }

  Future<String> getExamName(String examId) async {
    if (examCache.containsKey(examId)) {
      return examCache[examId]!;
    }

    final doc = await FirebaseFirestore.instance
        .collection("exams")
        .doc(examId)
        .get();

    final name = doc.data()?["title"] ?? "Unknown Exam";
    examCache[examId] = name;

    return name;
  }

  Future<void> deleteAttempt(BuildContext context, String docId) async {
    await FirebaseFirestore.instance
        .collection("examAttempts")
        .doc(docId)
        .delete();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Deleted successfully")));
  }

  void showDeleteDialog({
    required BuildContext context,
    required VoidCallback onDelete,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    IconlyLight.delete,
                    color: Colors.red,
                    size: 30.sp,
                  ),
                ),
                SizedBox(height: 15.h),
                Text(
                  "Delete Attempt",
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10.h),
                Text(
                  "Are you sure you want to delete this attempt?\nThis action cannot be undone.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                ),
                SizedBox(height: 20.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: Text(
                          "Cancel",
                          style: TextStyle(
                            fontSize: 20.sp,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          onDelete();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: Text(
                          "Delete",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20.sp,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back_ios),
        ),
        backgroundColor: AppColors.whiteColor,
        title: const Text("Top Grades"),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("examAttempts")
            .orderBy("score", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading data"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final attempts = snapshot.data!.docs;
          if (attempts.isEmpty) {
            return Center(child: Lottie.asset("assets/lottie/Empty.json"));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: attempts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final doc = attempts[index];
              final data = doc.data() as Map<String, dynamic>;

              final userId = data["userId"];
              final examId = data["examId"];
              final score = data["score"] ?? 0;

              return FutureBuilder<String>(
                future: getUserName(userId),
                builder: (context, userSnap) {
                  final userName = userSnap.data ?? "Loading...";

                  return FutureBuilder<String>(
                    future: getExamName(examId),
                    builder: (context, examSnap) {
                      final examName = examSnap.data ?? "Loading...";

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.blue,
                              child: Text(
                                "${index + 1}",
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 12),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    userName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16.sp,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    examName,
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 6.h,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Text(
                                "$score",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ),

                            SizedBox(width: 10.w),

                            IconButton(
                              icon: const Icon(
                                IconlyLight.delete,
                                color: Colors.red,
                              ),
                              onPressed: () {
                                showDeleteDialog(
                                  context: context,
                                  onDelete: () async {
                                    await deleteAttempt(context, doc.id);
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
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
