import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';

class CustomContainerSiginWithGoogle extends StatelessWidget {
  const CustomContainerSiginWithGoogle({super.key, this.onTap});
  final Function()? onTap;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(10.r),
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          color: Colors.grey.shade200,
        ),
        child: Row(
          mainAxisAlignment: .center,
          children: [
            Center(
              child: Text(
                "Sign in with Google",
                style: TextStyle(fontSize: 20.sp),
              ),
            ),
            SizedBox(width: 5.w),
            SvgPicture.asset("assets/icons/google.svg"),
          ],
        ),
      ),
    );
  }
}
