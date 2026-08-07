import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:platformexamapp/core/theme/app_page_route.dart';
import 'package:platformexamapp/features/admin/ui/dashboard.dart';
import 'package:platformexamapp/features/auth/data/models/user_data.dart';
import 'package:platformexamapp/features/exams/ui/exam_list_screen.dart';
import 'package:platformexamapp/features/home/ui/widgets/custom_container.dart';
import 'package:platformexamapp/features/home/ui/widgets/post_container.dart';
import 'package:platformexamapp/features/profile/ui/profile_screen.dart';
import 'package:platformexamapp/features/states/ui/states_screen.dart';
import 'package:platformexamapp/features/home/ui/daily_content_screen.dart';

class BodyContainer extends StatelessWidget {
  const BodyContainer({super.key, required this.uid, required this.user});

  final String uid;
  final UserData user;

  /// 🔥 عدد الامتحانات اللي المستخدم لسه ما امتحنهاش
  Stream<int> getUnattemptedExamsCount() {
    return FirebaseFirestore.instance.collection("exams").snapshots().asyncMap((
      examSnapshot,
    ) async {
      final exams = examSnapshot.docs;

      final attempts = await FirebaseFirestore.instance
          .collection("examAttempts")
          .where("userId", isEqualTo: uid)
          .get();

      final attemptedExamIds = attempts.docs.map((e) => e["examId"]).toSet();

      int count = 0;

      for (var exam in exams) {
        if (!attemptedExamIds.contains(exam.id)) {
          count++;
        }
      }

      return count;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool hasDashboardAccess = user.canAccessDashboard;
    final int itemsCount = hasDashboardAccess ? 5 : 4;
    final double gridHeight = (itemsCount / 2).ceil() * 130.h;

    return Container(
      padding: EdgeInsets.all(16.r),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30.r),
          topRight: Radius.circular(30.r),
        ),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "ready".tr(),
              style: TextStyle(fontSize: 26.sp, fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 10.h),

            SizedBox(
              height: gridHeight,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: itemsCount,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.25,
                ),
                itemBuilder: (context, index) {
                  final items = [
                    "exams",
                    if (hasDashboardAccess) "dashboard",
                    "results",
                    "profile",
                    "today_content",
                  ];

                  final item = items[index];

                  if (item == "exams") {
                    return StreamBuilder<int>(
                      stream: getUnattemptedExamsCount(),
                      builder: (context, snapshot) {
                        final newCount = snapshot.data ?? 0;

                        return Stack(
                          children: [
                            CustomContainer(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  AppPageRoute(child: ExamsScreen(user: user)),
                                );
                              },
                              title: "exams".tr(),
                              icon: HugeIcons.strokeRoundedFile01,
                              color: Colors.green,
                            ),

                            if (newCount > 0)
                              Positioned(
                                right: 5,
                                top: 5,
                                child: Container(
                                  padding: EdgeInsets.all(6.r),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    "$newCount",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    );
                  }

                  if (item == "dashboard") {
                    return CustomContainer(
                      onTap: () {
                        Navigator.push(
                          context,
                          AppPageRoute(child: AdminDashboardScreen(user: user)),
                        );
                      },
                      title: "dashboard".tr(),
                      icon: HugeIcons.strokeRoundedSettings01,
                      color: Colors.indigo,
                    );
                  }

                  if (item == "results") {
                    return CustomContainer(
                      title: "results".tr(),
                      icon: HugeIcons.strokeRoundedChart01,
                      color: Colors.blue,
                      onTap: () {
                        Navigator.push(
                          context,
                          AppPageRoute(child: LeaderboardScreen()),
                        );
                      },
                    );
                  }

                  if (item == "profile") {
                    return CustomContainer(
                      title: "profile".tr(),
                      icon: HugeIcons.strokeRoundedUser02,
                      color: Colors.red,
                      onTap: () {
                        Navigator.push(
                          context,
                          AppPageRoute(child: const ProfileScreen()),
                        );
                      },
                    );
                  }

                  return CustomContainer(
                    title: "todays_material".tr(),
                    icon: HugeIcons.strokeRoundedFileBookmark,
                    color: Colors.purple,
                    onTap: () {
                      Navigator.push(
                        context,
                        AppPageRoute(child: const DailyContentScreen()),
                      );
                    },
                  );
                },
              ),
            ),

            const Divider(),

            SizedBox(height: 5.h),

            Text(
              "egtma3na_posts".tr(),
              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 10.h),

            /// POSTS
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("posts")
                  .orderBy("createdAt", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final posts = snapshot.data!.docs;

                if (posts.isEmpty) {
                  return Center(
                    child: Text(
                      "no_posts_found".tr(),
                      style: const TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: posts.length,
                  separatorBuilder: (_, __) => SizedBox(height: 10.h),
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    final data = post.data() as Map<String, dynamic>;
                    final text = data["text"] ?? "";
                    final Map likes = data["likes"] ?? {};
                    final isLiked = likes.containsKey(uid);
                    final likeCount = likes.length;

                    final isArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(text);

                    return PostContainer(
                      isArabic: isArabic,
                      isLiked: isLiked,
                      text: text,
                      user: user,
                      uid: uid,
                      likeCount: likeCount,
                      post: post,
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
