import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor,

      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryColor,
                    AppColors.primaryColor.withOpacity(0.85),
                  ],
                ),
              ),
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

                  SizedBox(width: 12.w),

                  Text(
                    "All Users",
                    style: TextStyle(
                      fontSize: 22.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            /// ⚪ BODY
            Expanded(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(25.r),
                    topRight: Radius.circular(25.r),
                  ),
                ),
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("users")
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(child: Text("Error loading users"));
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final users = snapshot.data!.docs;

                    if (users.isEmpty) {
                      return Center(
                        child: Lottie.asset("assets/lottie/Empty.json"),
                      );
                    }

                    return ListView.separated(
                      itemCount: users.length,
                      separatorBuilder: (_, __) => SizedBox(height: 12.h),
                      itemBuilder: (context, index) {
                        final user =
                            users[index].data() as Map<String, dynamic>;

                        final name = user["name"] ?? "No Name";
                        final email = user["email"] ?? "No Email";
                        final isAdmin = user["isAdmin"] == true;

                        return Container(
                          padding: EdgeInsets.all(14.r),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16.r),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              /// 👤 AVATAR
                              Container(
                                width: 50.w,
                                height: 50.h,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: isAdmin
                                        ? [Colors.red, Colors.redAccent]
                                        : [Colors.blue, Colors.blueAccent],
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    name.isNotEmpty
                                        ? name[0].toUpperCase()
                                        : "?",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),

                              SizedBox(width: 12.w),

                              /// 📄 INFO
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    SizedBox(height: 4.h),

                                    Text(
                                      email,
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 13.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              /// 🏷 ROLE
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10.w,
                                  vertical: 6.h,
                                ),
                                decoration: BoxDecoration(
                                  color: isAdmin
                                      ? Colors.red.withOpacity(0.15)
                                      : Colors.green.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Text(
                                  isAdmin ? "Admin" : "User",
                                  style: TextStyle(
                                    color: isAdmin ? Colors.red : Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.sp,
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
            ),
          ],
        ),
      ),
    );
  }
}
