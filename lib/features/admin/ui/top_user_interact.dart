import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconly/iconly.dart';
import 'package:lottie/lottie.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';

class TopUsersScreen extends StatelessWidget {
  const TopUsersScreen({super.key});

  /// ================= STREAM POSTS =================
  Stream<List<Map<String, dynamic>>> getTopUsersStream() {
    return FirebaseFirestore.instance.collection("posts").snapshots().map((
      snapshot,
    ) {
      Map<String, int> likesCount = {};

      for (var post in snapshot.docs) {
        final data = post.data();
        final likes = data["likes"];

        if (likes is Map) {
          likes.forEach((uid, value) {
            if (value == true) {
              likesCount[uid] = (likesCount[uid] ?? 0) + 1;
            }
          });
        } else if (likes is List) {
          for (var uid in likes) {
            if (uid != null) {
              likesCount[uid] = (likesCount[uid] ?? 0) + 1;
            }
          }
        }
      }

      return likesCount.entries.map((e) {
        return {"uid": e.key, "likes": e.value};
      }).toList();
    });
  }

  /// ================= DELETE =================
  Future<void> deleteUserLikes(String uid, BuildContext context) async {
    final posts = await FirebaseFirestore.instance.collection("posts").get();

    for (var post in posts.docs) {
      await post.reference.update({"likes.$uid": FieldValue.delete()});
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Removed successfully")));
  }

  /// ================= USER DATA =================
  Future<Map<String, dynamic>> getUser(String uid) async {
    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .get();

    return {"name": doc.data()?["name"] ?? "Unknown"};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor,

      body: SafeArea(
        child: Column(
          children: [
            /// HEADER
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "Top Interactions❤️",
                      style: TextStyle(
                        fontSize: 26.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
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
                ],
              ),
            ),

            /// BODY
            Expanded(
              child: Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30.r),
                    topRight: Radius.circular(30.r),
                  ),
                ),

                child: StreamBuilder(
                  stream: getTopUsersStream(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final likesList =
                        snapshot.data as List<Map<String, dynamic>>;

                    if (likesList.isEmpty) {
                      return Center(
                        child: Lottie.asset("assets/lottie/Empty.json"),
                      );
                    }

                    /// SORT
                    likesList.sort((a, b) => b["likes"].compareTo(a["likes"]));

                    return ListView.separated(
                      itemCount: likesList.length,
                      separatorBuilder: (_, __) => SizedBox(height: 12.h),
                      itemBuilder: (context, index) {
                        final item = likesList[index];
                        final uid = item["uid"];

                        return FutureBuilder(
                          future: getUser(uid),
                          builder: (context, snap) {
                            final name = snap.data?["name"] ?? "Loading...";

                            return Container(
                              padding: EdgeInsets.all(16.r),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20.r),
                              ),

                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: AppColors.primaryColor,
                                    child: Text(
                                      "${index + 1}",
                                      style: TextStyle(
                                        fontWeight: .bold,
                                        color: AppColors.whiteColor,
                                      ),
                                    ),
                                  ),

                                  SizedBox(width: 12.w),

                                  Expanded(
                                    child: Text(
                                      name,
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),

                                  Text(
                                    "❤️ ${item["likes"]}",
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  IconButton(
                                    icon: const Icon(
                                      IconlyLight.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () =>
                                        deleteUserLikes(uid, context),
                                  ),
                                ],
                              ),
                            );
                          },
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
