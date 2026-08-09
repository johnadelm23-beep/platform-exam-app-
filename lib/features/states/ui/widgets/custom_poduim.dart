import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:platformexamapp/core/services/user_cache_service.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';

class CustomPoduim extends StatelessWidget {
  const CustomPoduim({
    super.key,
    required this.user,
    required this.rank,
    required this.color,
  });
  final Map<String, dynamic> user;
  final int rank;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextMain : AppColors.lightTextMain;

    final podiumHeight = rank == 1 ? 160.h : (rank == 2 ? 120.h : 90.h);
    final badgeColor = rank == 1
        ? AppColors.softGold
        : (rank == 2 ? const Color(0xFFC0C0C0) : const Color(0xFFCD7F32));

    return FutureBuilder<String>(
      future: UserCacheService.getUserName(user["userId"]),
      builder: (context, snap) {
        final name = snap.data ?? "...";

        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: rank == 1 ? 64.r : 52.r,
                  height: rank == 1 ? 64.r : 52.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: badgeColor.withOpacity(0.2),
                    border: Border.all(color: badgeColor, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: badgeColor.withOpacity(0.3),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      "$rank",
                      style: GoogleFonts.cairo(
                        color: badgeColor,
                        fontWeight: FontWeight.w900,
                        fontSize: rank == 1 ? 22.sp : 18.sp,
                      ),
                    ),
                  ),
                ),
                if (rank == 1)
                  Positioned(
                    top: -6.h,
                    child: Icon(
                      Icons.workspace_premium_rounded,
                      color: AppColors.goldLight,
                      size: 20.r,
                    ),
                  ),
              ],
            ),
            SizedBox(height: 8.h),
            SizedBox(
              width: 80.w,
              child: Text(
                name,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.sp,
                  color: textColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: AppColors.softGold.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Text(
                "${user["totalScore"]} pts",
                style: GoogleFonts.cairo(
                  fontSize: 11.sp,
                  color: AppColors.softGold,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 8.h),
            Container(
              width: 76.w,
              height: podiumHeight,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    badgeColor.withOpacity(0.35),
                    badgeColor.withOpacity(0.10),
                  ],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
                border: Border.all(
                  color: badgeColor.withOpacity(0.4),
                  width: 1.5,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
