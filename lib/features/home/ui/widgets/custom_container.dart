import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';

class CustomContainer extends StatelessWidget {
  final String title;
  final dynamic icon;
  final Color color;
  final Function()? onTap;
  const CustomContainer({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      //height: 70.h,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15.r),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(15.r),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon is IconData)
              Icon(icon as IconData, size: 35.sp, color: color)
            else if (icon is List<List<dynamic>>)
              HugeIcon(icon: icon as List<List<dynamic>>, size: 35.sp, color: color)
            else
              Icon(Icons.star, size: 35.sp, color: color),
            SizedBox(height: 10.h),
            Text(
              title,
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
