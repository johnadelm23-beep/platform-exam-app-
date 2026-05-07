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

    return doc.data()?["name"] ?? "Unknown";
  }

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

  Future<void> deleteAttempt(BuildContext context, String docId) async {
    await FirebaseFirestore.instance
        .collection("examAttempts")
        .doc(docId)
        .delete();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Deleted successfully"),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void showDeleteDialog({
    required BuildContext context,
    required VoidCallback onDelete,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Padding(
            padding: EdgeInsets.all(20.r),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(IconlyLight.delete, color: Colors.red, size: 40.r),

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
                  "Are you sure you want to delete this attempt?",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),

                SizedBox(height: 20.h),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          "Cancel",
                          style: TextStyle(
                            fontSize: 18.sp,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(width: 10.w),

                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          onDelete();
                        },
                        child: Text(
                          "Delete",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18.sp,
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
      backgroundColor: AppColors.primaryColor,

      body: SafeArea(
        child: Column(
          children: [
            /// 🔵 HEADER (same system)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryColor,
                    AppColors.primaryColor.withOpacity(0.85),
                  ],
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: EdgeInsets.all(10.r),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),

                  SizedBox(width: 12.w),

                  Text(
                    "Top Grades 🏆",
                    style: TextStyle(
                      fontSize: 22.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            /// ⚪ BODY
            Expanded(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(25.r),
                    topRight: Radius.circular(25.r),
                  ),
                ),
                child: StreamBuilder<QuerySnapshot>(
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
                      return Center(
                        child: Lottie.asset("assets/lottie/Empty.json"),
                      );
                    }

                    return ListView.separated(
                      itemCount: attempts.length,
                      separatorBuilder: (_, __) => SizedBox(height: 12.h),
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
                                  padding: EdgeInsets.all(14.r),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16.r),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 8,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      /// 🔢 RANK
                                      Container(
                                        width: 45.w,
                                        height: 45.h,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.blue,
                                        ),
                                        child: Center(
                                          child: Text(
                                            "${index + 1}",
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),

                                      SizedBox(width: 12.w),

                                      /// 📄 INFO
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              userName,
                                              style: TextStyle(
                                                fontSize: 15.sp,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(height: 4.h),
                                            Text(
                                              examName,
                                              style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 13.sp,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      /// 🟢 SCORE
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 10.w,
                                          vertical: 6.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(
                                            8.r,
                                          ),
                                        ),
                                        child: Text(
                                          "$score",
                                          style: const TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),

                                      SizedBox(width: 10.w),

                                      /// 🗑 DELETE
                                      IconButton(
                                        icon: const Icon(
                                          IconlyLight.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () {
                                          showDeleteDialog(
                                            context: context,
                                            onDelete: () async {
                                              await deleteAttempt(
                                                context,
                                                doc.id,
                                              );
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
