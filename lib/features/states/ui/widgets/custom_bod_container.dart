import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:platformexamapp/core/services/user_cache_service.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';
import 'package:platformexamapp/core/widgets/glass_card.dart';
import 'package:platformexamapp/features/states/ui/widgets/custom_poduim.dart';

class CustomBodyContainer extends StatelessWidget {
  const CustomBodyContainer({
    super.key,
    required this.top3,
    required this.others,
  });
  final List<Map<String, dynamic>> top3;
  final List<Map<String, dynamic>> others;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.darkSurface
        : AppColors.lightSurface;
    final textColor = isDark ? AppColors.darkTextMain : AppColors.lightTextMain;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32.r),
          topRight: Radius.circular(32.r),
        ),
        border: Border(top: BorderSide(color: borderColor, width: 1)),
      ),
      child: Column(
        children: [
          SizedBox(height: 10.h),

          SizedBox(
            height: 250.h,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (top3.length > 1)
                  CustomPoduim(
                    user: top3[1],
                    rank: 2,
                    color: const Color(0xFFC0C0C0),
                  ),
                if (top3.isNotEmpty)
                  CustomPoduim(
                    user: top3[0],
                    rank: 1,
                    color: AppColors.softGold,
                  ),
                if (top3.length > 2)
                  CustomPoduim(
                    user: top3[2],
                    rank: 3,
                    color: const Color(0xFFCD7F32),
                  ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          Divider(color: borderColor),
          SizedBox(height: 8.h),

          Expanded(
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              itemCount: others.length,
              separatorBuilder: (_, _) => SizedBox(height: 10.h),
              itemBuilder: (context, index) {
                final user = others[index];

                return FutureBuilder<String>(
                  future: UserCacheService.getUserName(user["userId"]),
                  builder: (context, snap) {
                    final name = snap.data ?? "...";

                    return GlassCard(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                      borderRadius: 16.r,
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.softGold.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Text(
                              "#${index + 4}",
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.bold,
                                color: AppColors.softGold,
                                fontSize: 13.sp,
                              ),
                            ),
                          ),
                          SizedBox(width: 14.w),

                          Expanded(
                            child: Text(
                              name,
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.bold,
                                fontSize: 15.sp,
                                color: textColor,
                              ),
                            ),
                          ),

                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 6.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.successGreen.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: AppColors.successGreen.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              "${user["totalScore"]} pts",
                              style: GoogleFonts.cairo(
                                color: AppColors.successGreen,
                                fontWeight: FontWeight.bold,
                                fontSize: 13.sp,
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
}
