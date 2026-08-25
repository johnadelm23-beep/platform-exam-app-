import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';
import 'package:platformexamapp/core/theme/app_page_route.dart';
import 'package:platformexamapp/features/admin/ui/add_exam_screen.dart';
import 'package:platformexamapp/features/admin/ui/add_post_screen.dart';
import 'package:platformexamapp/features/admin/ui/states_screen.dart';
import 'package:platformexamapp/features/admin/ui/top_user_interact.dart';
import 'package:platformexamapp/features/admin/ui/users_screen.dart';
import 'package:platformexamapp/features/auth/data/models/user_data.dart';
import 'package:platformexamapp/features/home/ui/widgets/custom_container.dart';

import 'package:platformexamapp/features/admin/ui/scanner_screen.dart';
import 'package:platformexamapp/features/admin/ui/events_screen.dart';
import 'package:platformexamapp/features/admin/ui/attendance_analytics_dashboard.dart';
import 'package:platformexamapp/features/admin/ui/daily_content_management.dart';
import 'package:platformexamapp/features/admin/ui/daily_content_history.dart';
import 'package:platformexamapp/features/admin/ui/seasons_management.dart';
import 'package:platformexamapp/features/admin/ui/admin_follow_up_screen.dart';
import 'package:platformexamapp/features/admin/ui/admin_bonus_screen.dart';
import 'package:platformexamapp/features/admin/ui/admin_games_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key, required this.user});
  final UserData user;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageBg = isDark ? AppColors.darkPageBg : AppColors.lightPageBg;
    final textColor = isDark ? AppColors.darkTextMain : AppColors.lightTextMain;
    final surfaceColor = isDark
        ? AppColors.darkSurface
        : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    if (!user.canAccessDashboard) {
      return Scaffold(
        backgroundColor: pageBg,
        appBar: AppBar(
          title: Text(
            "Access Denied",
            style: GoogleFonts.cairo(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: pageBg,
          elevation: 0,
        ),
        body: Center(
          child: Text(
            "You do not have permission to access the Dashboard.",
            style: GoogleFonts.cairo(color: textColor, fontSize: 16.sp),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: pageBg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: EdgeInsets.all(10.r),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.08)
                            : Colors.black.withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_back_ios,
                        color: textColor,
                        size: 18.r,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "welcome_name".tr(args: [user.name ?? "Admin"]),
                          style: GoogleFonts.cairo(
                            fontSize: 22.sp,
                            color: textColor,
                            fontWeight: FontWeight.w900,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          "Admin & Control Center",
                          style: GoogleFonts.cairo(
                            fontSize: 12.sp,
                            color: AppColors.softGold,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Container(
                padding: EdgeInsets.all(16.r),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32.r),
                    topRight: Radius.circular(32.r),
                  ),
                  border: Border(top: BorderSide(color: borderColor, width: 1)),
                ),
                child: GridView.count(
                  physics: const BouncingScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12.w,
                  mainAxisSpacing: 12.h,
                  childAspectRatio: 1.2,
                  children: [
                    if (user.canAccessFollowUp)
                      CustomContainer(
                        title: "Follow Up",
                        icon: HugeIcons.strokeRoundedCustomerSupport,
                        color: Colors.deepOrange.shade400,
                        onTap: () {
                          Navigator.push(
                            context,
                            AppPageRoute(child: const AdminFollowUpScreen()),
                          );
                        },
                      ),
                    if (user.canAccessScanner)
                      CustomContainer(
                        title: "attendance_scanner".tr(),
                        icon: HugeIcons.strokeRoundedQrCode,
                        color: AppColors.softGold,
                        onTap: () {
                          Navigator.push(
                            context,
                            AppPageRoute(child: const ScannerScreen()),
                          );
                        },
                      ),
                    if (user.canManageEvents)
                      CustomContainer(
                        title: "events_manager".tr(),
                        icon: HugeIcons.strokeRoundedCalendar01,
                        color: Colors.orange.shade400,
                        onTap: () {
                          Navigator.push(
                            context,
                            AppPageRoute(child: const EventsManagementScreen()),
                          );
                        },
                      ),
                    if (user.canAccessAttendanceState)
                      CustomContainer(
                        title: "attendance_stats".tr(),
                        icon: HugeIcons.strokeRoundedChart01,
                        color: AppColors.goldLight,
                        onTap: () {
                          Navigator.push(
                            context,
                            AppPageRoute(
                              child: AttendanceAnalyticsDashboard(user: user),
                            ),
                          );
                        },
                      ),
                    if (user.canCreateExam)
                      CustomContainer(
                        title: "add_exam".tr(),
                        icon: HugeIcons.strokeRoundedAdd01,
                        color: AppColors.successGreen,
                        onTap: () {
                          Navigator.push(
                            context,
                            AppPageRoute(child: const AddExamScreen()),
                          );
                        },
                      ),
                    if (user.canAccessUsers)
                      CustomContainer(
                        title: "users".tr(),
                        icon: HugeIcons.strokeRoundedUser,
                        color: AppColors.primaryLightNavy,
                        onTap: () {
                          Navigator.push(
                            context,
                            AppPageRoute(child: const UsersScreen()),
                          );
                        },
                      ),
                    if (user.canAccessGradeStates)
                      CustomContainer(
                        title: "stats".tr(),
                        icon: HugeIcons.strokeRoundedAnalytics01,
                        color: Colors.purple.shade400,
                        onTap: () {
                          Navigator.push(
                            context,
                            AppPageRoute(
                              child: ScoresStatisticsScreen(user: user),
                            ),
                          );
                        },
                      ),
                    if (user.canCreatePost)
                      CustomContainer(
                        title: "add_post".tr(),
                        icon: HugeIcons.strokeRoundedBookmark01,
                        color: AppColors.goldDark,
                        onTap: () {
                          Navigator.push(
                            context,
                            AppPageRoute(child: const AddPostScreen()),
                          );
                        },
                      ),
                    if (user.canAccessTopInteractions)
                      CustomContainer(
                        title: "top_interactions".tr(),
                        icon: HugeIcons.strokeRoundedFavourite,
                        color: AppColors.heartRed,
                        onTap: () {
                          Navigator.push(
                            context,
                            AppPageRoute(child: TopUsersScreen(user: user)),
                          );
                        },
                      ),
                    if (user.canCreateContent)
                      CustomContainer(
                        title: "daily_content_manager".tr(),
                        icon: HugeIcons.strokeRoundedFileBookmark,
                        color: Colors.teal.shade300,
                        onTap: () {
                          Navigator.push(
                            context,
                            AppPageRoute(
                              child: const DailyContentManagementScreen(),
                            ),
                          );
                        },
                      ),
                    if (user.canAccessContentHistory)
                      CustomContainer(
                        title: "content_history".tr(),
                        icon: HugeIcons.strokeRoundedFile01,
                        color: Colors.brown.shade400,
                        onTap: () {
                          Navigator.push(
                            context,
                            AppPageRoute(
                              child: DailyContentHistoryScreen(user: user),
                            ),
                          );
                        },
                      ),
                    if (user.canManageSeasons)
                      CustomContainer(
                        title: "seasons_manager".tr(),
                        icon: HugeIcons.strokeRoundedGrid,
                        color: Colors.blueGrey.shade400,
                        onTap: () {
                          Navigator.push(
                            context,
                            AppPageRoute(
                              child: const SeasonsManagementScreen(),
                            ),
                          );
                        },
                      ),
                    if (user.canManageBonus)
                      CustomContainer(
                        title: "bonus_management".tr(),
                        icon: HugeIcons.strokeRoundedAward01,
                        color: AppColors.softGold,
                        onTap: () {
                          Navigator.push(
                            context,
                            AppPageRoute(
                              child: AdminBonusScreen(user: user),
                            ),
                          );
                        },
                      ),
                    // CustomContainer(
                    //   title: "games_management".tr(),
                    //   icon: HugeIcons.strokeRoundedGameController01,
                    //   color: AppColors.softGold,
                    //   onTap: () {
                    //     Navigator.push(
                    //       context,
                    //       AppPageRoute(
                    //         child: AdminGamesScreen(user: user),
                    //       ),
                    //     );
                    //   },
                    // ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
