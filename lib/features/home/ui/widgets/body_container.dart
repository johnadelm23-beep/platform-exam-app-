import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconly/iconly.dart';
import 'package:lottie/lottie.dart';
import 'package:platformexamapp/features/admin/ui/dashboard.dart';
import 'package:platformexamapp/features/auth/data/models/user_data.dart';
import 'package:platformexamapp/features/exams/ui/exam_list_screen.dart';
import 'package:platformexamapp/features/home/ui/widgets/custom_container.dart';
import 'package:platformexamapp/features/home/ui/widgets/post_container.dart';
import 'package:platformexamapp/features/profile/ui/profile_screen.dart';
import 'package:platformexamapp/features/states/ui/states_screen.dart';

class BodyContainer extends StatelessWidget {
  const BodyContainer({super.key, required this.uid, required this.user});
  final String uid;
  final UserData user;
  @override
  Widget build(BuildContext context) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Ready!",
            style: TextStyle(fontSize: 26.sp, fontWeight: FontWeight.bold),
          ),

          SizedBox(height: 10.h),

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
                  icon: IconlyLight.document,
                  color: Colors.green,
                ),

                if (user.isAdmin == true)
                  CustomContainer(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (c) => AdminDashboardScreen(user: user),
                        ),
                      );
                    },
                    title: "Dashboard",
                    icon: IconlyLight.setting,
                    color: Colors.indigo,
                  ),

                CustomContainer(
                  title: "Results",
                  icon: IconlyLight.chart,
                  color: Colors.blue,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (c) => LeaderboardScreen()),
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
                      MaterialPageRoute(builder: (c) => ProfileScreen()),
                    );
                  },
                ),
              ],
            ),
          ),

          const Divider(),

          SizedBox(height: 5.h),

          Text(
            "Egtma3na Posts 😊",
            style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
          ),

          SizedBox(height: 10.h),

          /// POSTS
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("posts")
                  .orderBy("createdAt", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final posts = snapshot.data?.docs ?? [];

                if (posts.isEmpty) {
                  return Center(
                    child: Lottie.asset("assets/lottie/not found.json"),
                  );
                }

                return ListView.separated(
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
          ),
        ],
      ),
    );
  }
}
