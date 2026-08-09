import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:platformexamapp/core/services/user_cache_service.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';
import 'package:platformexamapp/core/widgets/empty_state.dart';
import 'package:platformexamapp/core/widgets/glass_card.dart';
import 'package:platformexamapp/core/widgets/loading_state.dart';
import 'package:platformexamapp/features/auth/data/models/user_data.dart';

class TopUsersScreen extends StatefulWidget {
  const TopUsersScreen({super.key, this.user});
  final UserData? user;

  @override
  State<TopUsersScreen> createState() => _TopUsersScreenState();
}

class _TopUsersScreenState extends State<TopUsersScreen> {
  late final Stream<List<Map<String, dynamic>>> _topUsersStream;

  @override
  void initState() {
    super.initState();
    _topUsersStream = getTopUsersStream();
  }

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

  Future<void> deleteUserLikes(String uid, BuildContext context) async {
    final posts = await FirebaseFirestore.instance.collection("posts").get();

    for (var post in posts.docs) {
      await post.reference.update({"likes.$uid": FieldValue.delete()});
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Removed successfully", style: GoogleFonts.cairo()),
          backgroundColor: AppColors.successGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageBg = isDark ? AppColors.darkPageBg : AppColors.lightPageBg;
    final textColor = isDark ? AppColors.darkTextMain : AppColors.lightTextMain;
    final surfaceColor = isDark
        ? AppColors.darkSurface
        : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Scaffold(
      backgroundColor: pageBg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(16.r),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "Top Interactions ❤️",
                      style: GoogleFonts.cairo(
                        fontSize: 22.sp,
                        color: textColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
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
                ],
              ),
            ),

            Expanded(
              child: Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32.r),
                    topRight: Radius.circular(32.r),
                  ),
                  border: Border(top: BorderSide(color: borderColor, width: 1)),
                ),
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _topUsersStream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const LoadingState();
                    }

                    final likesList = snapshot.data ?? [];

                    if (likesList.isEmpty) {
                      return EmptyState(
                        title: "No Interactions Yet",
                        hugeIcon: HugeIcons.strokeRoundedFavourite,
                      );
                    }

                    likesList.sort((a, b) => b["likes"].compareTo(a["likes"]));

                    return ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      itemCount: likesList.length,
                      separatorBuilder: (_, __) => SizedBox(height: 12.h),
                      itemBuilder: (context, index) {
                        final item = likesList[index];
                        final uid = item["uid"];

                        return FutureBuilder<String>(
                          future: UserCacheService.getUserName(uid),
                          builder: (context, snap) {
                            final name = snap.data ?? "Loading...";

                            return GlassCard(
                              padding: EdgeInsets.all(16.r),
                              borderRadius: 20.r,
                              child: Row(
                                children: [
                                  Container(
                                    width: 36.r,
                                    height: 36.r,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: index == 0
                                          ? AppColors.softGold
                                          : AppColors.softGold.withOpacity(0.2),
                                    ),
                                    child: Center(
                                      child: Text(
                                        "${index + 1}",
                                        style: GoogleFonts.cairo(
                                          fontWeight: FontWeight.bold,
                                          color: index == 0
                                              ? AppColors.cinematicNavy
                                              : AppColors.softGold,
                                          fontSize: 14.sp,
                                        ),
                                      ),
                                    ),
                                  ),

                                  SizedBox(width: 12.w),

                                  Expanded(
                                    child: Text(
                                      name,
                                      style: GoogleFonts.cairo(
                                        fontSize: 15.sp,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),
                                  ),

                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10.w,
                                      vertical: 4.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.heartRed.withOpacity(
                                        0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                    child: Text(
                                      "❤️ ${item["likes"]}",
                                      style: GoogleFonts.cairo(
                                        color: AppColors.heartRed,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13.sp,
                                      ),
                                    ),
                                  ),

                                  if (widget.user?.isAdminVal == true)
                                    IconButton(
                                      icon: const HugeIcon(
                                        icon: HugeIcons.strokeRoundedDelete01,
                                        color: AppColors.heartRed,
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
