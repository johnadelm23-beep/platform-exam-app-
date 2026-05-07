import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';

class CustomBodyContainer extends StatelessWidget {
  const CustomBodyContainer({super.key, required this.docs});
  final List<QueryDocumentSnapshot<Object?>> docs;
  @override
  Widget build(BuildContext context) {
    return Container(
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
            style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
          ),

          SizedBox(height: 15.h),

          Expanded(
            child: ListView.separated(
              itemCount: docs.length,
              separatorBuilder: (_, __) => SizedBox(height: 12.h),
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data() as Map<String, dynamic>;

                final examId = data["examId"];
                final score = data["score"] ?? 0;

                return FutureBuilder<String>(
                  future: getExamName(examId),
                  builder: (context, examSnap) {
                    final examName = examSnap.data ?? "Loading...";

                    return Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),

                      child: Row(
                        children: [
                          Icon(Icons.book, color: AppColors.primaryColor),

                          SizedBox(width: 10.w),

                          Expanded(
                            child: Text(
                              examName,
                              style: TextStyle(fontSize: 15.sp),
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
    );
  }

  static final Map<String, String> examCache = {};
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
}
