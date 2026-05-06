import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';

class CustomTextRich extends StatelessWidget {
  const CustomTextRich({super.key, required this.text1, required this.text2});
  final String text1;
  final String text2;
  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: "${text1} ",
            style: TextStyle(fontSize: 16.sp, fontWeight: .bold),
          ),
          TextSpan(
            text: text2,
            style: TextStyle(
              fontSize: 16.sp,

              color: AppColors.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
