import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';
import 'package:platformexamapp/features/profile/ui/widgets/custom_state_container.dart';

class CustomAppBarProfile extends StatelessWidget {
  const CustomAppBarProfile({
    super.key,
    required this.name,
    required this.totalScore,
    required this.docs,
    required this.rank,
  });
  final String name;
  final int totalScore;
  final List<QueryDocumentSnapshot<Object?>> docs;
  final int rank;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 25.h, horizontal: 16.w),
      decoration: const BoxDecoration(color: AppColors.primaryColor),
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

          Wrap(
            spacing: 12.w,
            runSpacing: 10.h,
            alignment: WrapAlignment.center,
            children: [
              CustomStateContainer(title: "Score", value: "$totalScore"),
              CustomStateContainer(title: "Exams", value: "${docs.length}"),
              CustomStateContainer(title: "Rank", value: "#$rank"),
            ],
          ),
        ],
      ),
    );
  }
}
