import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:iconly/iconly.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';
import 'package:platformexamapp/features/auth/data/models/user_data.dart';
import 'package:platformexamapp/features/exams/ui/exam_details_screen.dart';

class ExamsScreen extends StatelessWidget {
  const ExamsScreen({super.key, required this.user});
  final UserData user;
  Future<void> deleteExam(String examId) async {
    await FirebaseFirestore.instance.collection("exams").doc(examId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(16.r),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "Avaliable Exams",
                      style: TextStyle(
                        fontSize: 26.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
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
                ],
              ),
            ),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(30.r),
                  ),
                ),
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("exams")
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final exams = snapshot.data!.docs;
                    if (exams.isEmpty) {
                      return Center(
                        child: Lottie.asset("assets/lottie/Empty.json"),
                      );
                    }
                    return ListView.separated(
                      itemCount: exams.length,
                      separatorBuilder: (_, _) => SizedBox(height: 10.h),
                      itemBuilder: (context, index) {
                        final exam = exams[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ExamDetailsScreen(
                                  examId: exam.id,
                                  title: exam["title"],
                                  time: exam["time"],
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.all(16.r),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  IconlyLight.document,
                                  color: Colors.green,
                                ),
                                SizedBox(width: 10.w),
                                Expanded(
                                  child: Text(
                                    exam["title"],
                                    style: TextStyle(fontSize: 16.sp),
                                  ),
                                ),
                                if (user.isAdmin == true)
                                  IconButton(
                                    icon: const Icon(
                                      IconlyLight.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () async {
                                      await deleteExam(exam.id);
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text("Deleted"),
                                        ),
                                      );
                                    },
                                  ),
                              ],
                            ),
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
