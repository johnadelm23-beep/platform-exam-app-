import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconly/iconly.dart';
import 'package:lottie/lottie.dart';

import 'package:platformexamapp/core/theme/app_colors.dart';
import 'package:platformexamapp/features/admin/ui/dashboard.dart';
import 'package:platformexamapp/features/auth/cubit/cubit/auth_cubit.dart';
import 'package:platformexamapp/features/auth/ui/login_screen.dart';
import 'package:platformexamapp/features/exams/ui/exam_list_screen.dart';
import 'package:platformexamapp/features/home/cubit/cubit/home_cubit.dart';
import 'package:platformexamapp/features/home/ui/widgets/custom_container.dart';
import 'package:platformexamapp/features/profile/ui/profile_screen.dart';
import 'package:platformexamapp/features/states/ui/states_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    context.read<HomeCubit>().getUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      body: SafeArea(
        child: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
            if (state is GetUserDataLoading) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }

            if (state is GetUserDaraError) {
              return const Center(
                child: Text(
                  "Error loading data",
                  style: TextStyle(color: Colors.white),
                ),
              );
            }

            final user = context.watch<HomeCubit>().userData;

            if (user == null) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// 👤 HEADER
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 16.h,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Hello, ${user.name} 😎",
                          style: TextStyle(
                            fontSize: 26.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      IconButton(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();

                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BlocProvider(
                                create: (_) => AuthCubit(),
                                child: const LoginScreen(),
                              ),
                            ),
                            (route) => false,
                          );
                        },
                        icon: Icon(
                          IconlyLight.logout,
                          color: Colors.white,
                          size: 24.r,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 5.h),

                /// 📦 BODY
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Ready!",
                          style: TextStyle(
                            fontSize: 26.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        SizedBox(height: 10.h),

                        /// 📊 GRID
                        SizedBox(
                          height: 270.h,
                          child: GridView.count(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            children: [
                              CustomContainer(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (c) => ExamsScreen(user: user),
                                    ),
                                  );
                                },
                                title: "Exams",
                                icon: Icons.book,
                                color: Colors.green,
                              ),

                              if (user.isAdmin == true)
                                CustomContainer(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (c) =>
                                            AdminDashboardScreen(user: user),
                                      ),
                                    );
                                  },
                                  title: "Dashboard",
                                  icon: IconlyLight.setting,
                                  color: Colors.indigo,
                                ),

                              CustomContainer(
                                title: "Results",
                                icon: Icons.bar_chart,
                                color: Colors.blue,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (c) => LeaderboardScreen(),
                                    ),
                                  );
                                },
                              ),

                              CustomContainer(
                                title: "Profile",
                                icon: IconlyLight.profile,
                                color: Colors.red,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (c) => ProfileScreen(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        const Divider(),

                        const Text(
                          "Egtma3na Posts😊",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        SizedBox(height: 10.h),

                        /// 📢 POSTS
                        Expanded(
                          child: StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection("posts")
                                .orderBy("createdAt", descending: true)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              final posts = snapshot.data?.docs ?? [];

                              if (posts.isEmpty) {
                                return Center(
                                  child: Lottie.asset(
                                    "assets/lottie/not found.json",
                                  ),
                                );
                              }

                              return ListView.separated(
                                itemCount: posts.length,
                                separatorBuilder: (_, __) =>
                                    SizedBox(height: 10.h),
                                itemBuilder: (context, index) {
                                  final data =
                                      posts[index].data()
                                          as Map<String, dynamic>;

                                  final String text = data["text"] ?? "";

                                  final bool isArabic = RegExp(
                                    r'[\u0600-\u06FF]',
                                  ).hasMatch(text);

                                  return Directionality(
                                    textDirection: isArabic
                                        ? TextDirection.rtl
                                        : TextDirection.ltr,
                                    child: Container(
                                      padding: EdgeInsets.all(16.r),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(
                                          12.r,
                                        ),
                                        border: Border.all(
                                          color: Colors.blue.shade100,
                                        ),
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Icon(
                                            Icons.campaign,
                                            color: Colors.blue,
                                            size: 22.r,
                                          ),

                                          SizedBox(width: 10.w),

                                          Expanded(
                                            child: Text(
                                              text,
                                              textAlign: TextAlign.start,
                                              style: TextStyle(
                                                fontSize: 16.sp,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),

                                          if (user.isAdmin == true)
                                            IconButton(
                                              icon: const Icon(
                                                IconlyLight.delete,
                                                color: Colors.red,
                                              ),
                                              onPressed: () async {
                                                await FirebaseFirestore.instance
                                                    .collection("posts")
                                                    .doc(posts[index].id)
                                                    .delete();
                                              },
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
