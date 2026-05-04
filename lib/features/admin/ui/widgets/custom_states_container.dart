import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomStatesContainer extends StatelessWidget {
  const CustomStatesContainer({
    super.key,
    required this.value,
    required this.color,
    required this.title,
  });
  final String value;
  final Color color;
  final String title;
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(15.w),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 5.h),
            Text(title),
          ],
        ),
      ),
    );
    ;
  }
}
