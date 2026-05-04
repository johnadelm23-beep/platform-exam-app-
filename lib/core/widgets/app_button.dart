import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';

class AppButton extends StatelessWidget {
  const AppButton({super.key, required this.text, this.onPressed});
  final String text;
  final void Function()? onPressed;
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadiusGeometry.circular(12.r),
        ),
        minimumSize: Size(double.infinity, 60.h),
      ),
      onPressed: onPressed,
      child: Text(
        text,
        style: TextStyle(fontSize: 20.sp, color: AppColors.whiteColor),
      ),
    );
  }
}
