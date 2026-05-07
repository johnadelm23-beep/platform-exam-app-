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

  Future<void> deleteExam(BuildContext context, String examId) async {
    await FirebaseFirestore.instance.collection("exams").doc(examId).delete();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Exam deleted successfully")));
  }

  void showDeleteDialog(BuildContext context, String examId) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: AppColors.whiteColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Padding(
            padding: EdgeInsets.all(20.r),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning_rounded, color: Colors.red, size: 55.r),

                SizedBox(height: 12.h),

                Text(
                  "Delete Exam?",
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 8.h),

                Text(
                  "This action cannot be undone.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14.sp, color: Colors.black),
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
                          deleteExam(context, examId);
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// HEADER (no logout button anymore)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              child: Text(
                "Exams",
                style: TextStyle(
                  fontSize: 26.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            /// BODY
            Expanded(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30.r),
                    topRight: Radius.circular(30.r),
                  ),
                ),

                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("exams")
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Lottie.asset(
                              "assets/lottie/Empty.json",
                              height: 180.h,
                            ),
                            SizedBox(height: 10.h),
                            Text(
                              "No Exams Yet",
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final exams = snapshot.data!.docs;

                    return ListView.separated(
                      itemCount: exams.length,
                      separatorBuilder: (_, __) => SizedBox(height: 12.h),

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
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),

                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(12.r),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryColor.withOpacity(
                                      0.1,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.assignment,
                                    color: AppColors.primaryColor,
                                  ),
                                ),

                                SizedBox(width: 12.w),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        exam["title"],
                                        style: TextStyle(
                                          fontSize: 17.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 6.h),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.timer,
                                            size: 16.r,
                                            color: Colors.grey,
                                          ),
                                          SizedBox(width: 5.w),
                                          Text(
                                            "${exam["time"]} min",
                                            style: TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                if (user.isAdmin == true)
                                  IconButton(
                                    onPressed: () =>
                                        showDeleteDialog(context, exam.id),
                                    icon: const Icon(
                                      IconlyLight.delete,
                                      color: Colors.red,
                                    ),
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
