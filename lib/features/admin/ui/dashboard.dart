import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconly/iconly.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';
import 'package:platformexamapp/features/admin/ui/add_exam_screen.dart';
import 'package:platformexamapp/features/admin/ui/add_post_screen.dart';
import 'package:platformexamapp/features/admin/ui/states_screen.dart';
import 'package:platformexamapp/features/admin/ui/top_user_interact.dart';
import 'package:platformexamapp/features/admin/ui/users_screen.dart';
import 'package:platformexamapp/features/auth/data/models/user_data.dart';
import 'package:platformexamapp/features/home/ui/widgets/custom_container.dart';

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
                    "Welcome, ${user.name}😎",
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
                      title: "Add Exam",
                      icon: IconlyLight.plus,
                      color: Colors.green,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AddExamScreen(),
                          ),
                        );
                      },
                    ),
                    CustomContainer(
                      title: "Users",
                      icon: IconlyLight.user,
                      color: Colors.blue,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (c) => UsersScreen()),
                        );
                      },
                    ),

                    CustomContainer(
                      title: "Stats",
                      icon: IconlyLight.chart,
                      color: Colors.purple,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (c) => ScoresStatisticsScreen(),
                          ),
                        );
                      },
                    ),
                    CustomContainer(
                      title: "Add post",
                      icon: IconlyLight.bookmark,
                      color: Colors.amber,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (c) => AddPostScreen()),
                        );
                      },
                    ),
                    CustomContainer(
                      title: "Top Interactions",
                      icon: IconlyBold.heart,
                      color: Colors.red,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (c) => TopUsersScreen()),
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
