import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';
import 'package:platformexamapp/features/admin/ui/widgets/custom_acton_container.dart';
import 'package:platformexamapp/features/admin/ui/widgets/custom_states_container.dart';
import 'package:platformexamapp/features/auth/cubit/cubit/auth_cubit.dart';
import 'package:platformexamapp/features/auth/ui/login_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AuthCubit>().getUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(20.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  BlocBuilder<AuthCubit, AuthState>(
                    builder: (context, state) {
                      final user = context.read<AuthCubit>().userData;
                      return Text(
                        "Hello,${user?.name ?? "Ananomus"}",
                        style: TextStyle(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),

                  IconButton(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();

                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.logout, color: Colors.white),
                  ),
                ],
              ),
            ),

            SizedBox(height: 10.h),

            /// CONTENT
            Expanded(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30.r),
                    topRight: Radius.circular(30.r),
                  ),
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Overview",
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 20.h),

                    Row(
                      children: [
                        CustomStatesContainer(
                          value: "120",
                          color: Colors.blue,
                          title: "User",
                        ),
                        SizedBox(width: 10.w),
                        CustomStatesContainer(
                          title: "Exams",
                          value: "15",
                          color: Colors.green,
                        ),
                      ],
                    ),

                    SizedBox(height: 20.h),

                    Row(
                      children: [
                        CustomStatesContainer(
                          title: "Results",
                          value: "340",
                          color: Colors.orange,
                        ),
                        SizedBox(width: 10.w),
                        CustomStatesContainer(
                          title: "Pending",
                          value: "5",
                          color: Colors.red,
                        ),
                      ],
                    ),

                    SizedBox(height: 30.h),

                    Text(
                      "Actions",
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 15.h),

                    /// ACTION BUTTONS
                    CustomActonContainer(
                      title: "Add New Exam",
                      icon: Icons.add,
                      color: Colors.blue,
                    ),

                    CustomActonContainer(
                      title: "Manage Users",
                      icon: Icons.people,
                      color: Colors.green,
                    ),

                    CustomActonContainer(
                      title: "View Results",
                      icon: Icons.bar_chart,
                      color: Colors.orange,
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
