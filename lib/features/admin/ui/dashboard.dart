import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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

class AdminDashboardScreen extends StatelessWidget {

  const AdminDashboardScreen({super.key, required this.user});
  final UserData user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor,
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
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    "welcome_name".tr(args: [user.name ?? "Admin"]),
                    style: TextStyle(
                      fontSize: 24.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
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
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30.r),
                    topRight: Radius.circular(30.r),
                  ),
                ),
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: [
                    CustomContainer(
                      title: "Follow Up",
                      icon: HugeIcons.strokeRoundedCustomerSupport,
                      color: Colors.deepOrange,
                      onTap: () {
                        Navigator.push(
                          context,
                          AppPageRoute(
                            child: const AdminFollowUpScreen(),
                          ),
                        );
                      },
                    ),
                    CustomContainer(
                      title: "attendance_scanner".tr(),

                      icon: HugeIcons.strokeRoundedQrCode,
                      color: Colors.indigo,
                      onTap: () {
                        Navigator.push(
                          context,
                          AppPageRoute(
                            child: const ScannerScreen(),
                          ),
                        );
                      },
                    ),
                    CustomContainer(
                      title: "events_manager".tr(),
                      icon: HugeIcons.strokeRoundedCalendar01,
                      color: Colors.orange,
                      onTap: () {
                        Navigator.push(
                          context,
                          AppPageRoute(
                            child: const EventsManagementScreen(),
                          ),
                        );
                      },
                    ),
                    CustomContainer(
                      title: "attendance_stats".tr(),
                      icon: HugeIcons.strokeRoundedChart01,
                      color: Colors.pink,
                      onTap: () {
                        Navigator.push(
                          context,
                          AppPageRoute(
                            child: const AttendanceAnalyticsDashboard(),
                          ),
                        );
                      },
                    ),
                    CustomContainer(
                      title: "add_exam".tr(),
                      icon: HugeIcons.strokeRoundedAdd01,
                      color: Colors.green,
                      onTap: () {
                        Navigator.push(
                          context,
                          AppPageRoute(
                            child: const AddExamScreen(),
                          ),
                        );
                      },
                    ),
                    CustomContainer(
                      title: "users".tr(),
                      icon: HugeIcons.strokeRoundedUser,
                      color: Colors.blue,
                      onTap: () {
                        Navigator.push(
                          context,
                          AppPageRoute(child: UsersScreen()),
                        );
                      },
                    ),

                    CustomContainer(
                      title: "stats".tr(),
                      icon: HugeIcons.strokeRoundedAnalytics01,
                      color: Colors.purple,
                      onTap: () {
                        Navigator.push(
                          context,
                          AppPageRoute(
                            child: ScoresStatisticsScreen(),
                          ),
                        );
                      },
                    ),
                    CustomContainer(
                      title: "add_post".tr(),
                      icon: HugeIcons.strokeRoundedBookmark01,
                      color: Colors.amber,
                      onTap: () {
                        Navigator.push(
                          context,
                          AppPageRoute(child: AddPostScreen()),
                        );
                      },
                    ),
                    CustomContainer(
                      title: "top_interactions".tr(),
                      icon: HugeIcons.strokeRoundedFavourite,
                      color: Colors.red,
                      onTap: () {
                        Navigator.push(
                          context,
                          AppPageRoute(child: TopUsersScreen()),
                        );
                      },
                    ),
                    CustomContainer(
                      title: "daily_content_manager".tr(),
                      icon: HugeIcons.strokeRoundedFileBookmark,
                      color: Colors.teal,
                      onTap: () {
                        Navigator.push(
                          context,
                          AppPageRoute(
                            child: const DailyContentManagementScreen(),
                          ),
                        );
                      },
                    ),
                    CustomContainer(
                      title: "content_history".tr(),
                      icon: HugeIcons.strokeRoundedFile01,
                      color: Colors.brown,
                      onTap: () {
                        Navigator.push(
                          context,
                          AppPageRoute(
                            child: const DailyContentHistoryScreen(),
                          ),
                        );
                      },
                    ),
                    CustomContainer(
                      title: "seasons_manager".tr(),
                      icon: HugeIcons.strokeRoundedGrid,
                      color: Colors.blueGrey,
                      onTap: () {
                        Navigator.push(
                          context,
                          AppPageRoute(
                            child: const SeasonsManagementScreen(),
                          ),
                        );
                      },
                    ),
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
