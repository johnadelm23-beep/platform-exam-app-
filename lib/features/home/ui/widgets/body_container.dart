import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';
import 'package:platformexamapp/core/theme/app_page_route.dart';
import 'package:platformexamapp/core/widgets/empty_state.dart';
import 'package:platformexamapp/core/widgets/loading_state.dart';
import 'package:platformexamapp/core/widgets/section_header.dart';
import 'package:platformexamapp/features/admin/ui/dashboard.dart';
import 'package:platformexamapp/features/auth/data/models/user_data.dart';
import 'package:platformexamapp/features/exams/ui/exam_list_screen.dart';
import 'package:platformexamapp/features/home/ui/widgets/custom_container.dart';
import 'package:platformexamapp/features/home/ui/widgets/post_container.dart';
import 'package:platformexamapp/features/profile/ui/profile_screen.dart';
import 'package:platformexamapp/features/states/ui/states_screen.dart';
import 'package:platformexamapp/features/home/ui/daily_content_screen.dart';
import 'package:platformexamapp/features/bonus/ui/user_bonus_screen.dart';
import 'package:platformexamapp/features/games/ui/games_home_screen.dart';

class BodyContainer extends StatefulWidget {
  const BodyContainer({super.key, required this.uid, required this.user});

  final String uid;
  final UserData user;

  @override
  State<BodyContainer> createState() => _BodyContainerState();
}

class _BodyContainerState extends State<BodyContainer> {
  late final Stream<int> _unattemptedExamsStream;
  late final Stream<int> _unviewedBonusStream;
  late final Stream<QuerySnapshot> _postsStream;
  static final RegExp _arabicRegex = RegExp(r'[\u0600-\u06FF]');

  @override
  void initState() {
    super.initState();
    _unattemptedExamsStream = getUnattemptedExamsCount();
    _unviewedBonusStream = getUnviewedBonusCount();
    _postsStream = FirebaseFirestore.instance
        .collection("posts")
        .orderBy("createdAt", descending: true)
        .snapshots();
  }

  /// 🔥 عدد الامتحانات اللي المستخدم لسه ما امتحنهاش
  Stream<int> getUnattemptedExamsCount() {
    return FirebaseFirestore.instance.collection("exams").snapshots().asyncMap((
      examSnapshot,
    ) async {
      final exams = examSnapshot.docs;

      final attempts = await FirebaseFirestore.instance
          .collection("examAttempts")
          .where("userId", isEqualTo: widget.uid)
          .get();

      final attemptedExamIds = attempts.docs
          .where((e) => (e.data())["done"] == true)
          .map((e) => e["examId"])
          .toSet();

      int count = 0;

      for (var exam in exams) {
        if (!attemptedExamIds.contains(exam.id)) {
          count++;
        }
      }

      return count;
    });
  }

  /// 🌟 عدد إشعارات البونص الجديدة التي لم يشاهدها المستخدم بعد
  Stream<int> getUnviewedBonusCount() {
    return FirebaseFirestore.instance
        .collection("bonuses")
        .snapshots()
        .asyncMap((bonusesSnap) async {
      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(widget.uid)
          .get();

      final userData = userDoc.data();
      final lastViewed = userData?["lastBonusViewed"] as Timestamp?;

      int count = 0;
      for (var doc in bonusesSnap.docs) {
        final data = doc.data();
        final createdAt = data["createdAt"] as Timestamp?;
        if (createdAt != null) {
          if (lastViewed == null || createdAt.compareTo(lastViewed) > 0) {
            count++;
          }
        }
      }

      return count;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.darkSurface
        : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final bool hasDashboardAccess = widget.user.canAccessDashboard;
    final gridItems = [
      "exams",
      // "games", // Temporarily disabled for Kahoot stage pause
      if (hasDashboardAccess) "dashboard",
      "results",
      "bonus",
      "profile",
      "today_content",
    ];

    final int gridRows = (gridItems.length / 2).ceil();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
      width: double.infinity,
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32.r),
          topRight: Radius.circular(32.r),
        ),
        border: Border(top: BorderSide(color: borderColor, width: 1)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double availableWidth = constraints.maxWidth;
          final double cellWidth = (availableWidth - 12.w) / 2;
          final double normalCardHeight = cellWidth / 1.35;
          final double calcGridHeight =
              gridRows * normalCardHeight + (gridRows - 1) * 12.h;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(title: "ready".tr()),

                SizedBox(height: 12.h),

                SizedBox(
                  height: calcGridHeight,
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: gridItems.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12.w,
                      mainAxisSpacing: 12.h,
                      childAspectRatio: 1.35,
                    ),
                    itemBuilder: (context, index) {
                      final item = gridItems[index];

                      if (item == "exams") {
                        return StreamBuilder<int>(
                          stream: _unattemptedExamsStream,
                          builder: (context, snapshot) {
                            final newCount = snapshot.data ?? 0;

                            return Stack(
                              fit: StackFit.expand,
                              children: [
                                CustomContainer(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      AppPageRoute(
                                        child: ExamsScreen(user: widget.user),
                                      ),
                                    );
                                  },
                                  title: "exams".tr(),
                                  icon: HugeIcons.strokeRoundedFile01,
                                  color: AppColors.softGold,
                                ),
                                if (newCount > 0)
                                  Positioned(
                                    right: 8.w,
                                    top: 8.h,
                                    child: Container(
                                      padding: EdgeInsets.all(6.r),
                                      decoration: const BoxDecoration(
                                        color: AppColors.heartRed,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Color(0x66DC3545),
                                            blurRadius: 8,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        "$newCount",
                                        style: GoogleFonts.cairo(
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
                              AppPageRoute(
                                child: AdminDashboardScreen(user: widget.user),
                              ),
                            );
                          },
                          title: "dashboard".tr(),
                          icon: HugeIcons.strokeRoundedSettings01,
                          color: AppColors.primaryLightNavy,
                        );
                      }

                      if (item == "games") {
                        return CustomContainer(
                          title: "games".tr(),
                          icon: HugeIcons.strokeRoundedGameController01,
                          color: AppColors.softGold,
                          onTap: () {
                            Navigator.push(
                              context,
                              AppPageRoute(child: const GamesHomeScreen()),
                            );
                          },
                        );
                      }

                      if (item == "results") {
                        return CustomContainer(
                          title: "results".tr(),
                          icon: HugeIcons.strokeRoundedChart01,
                          color: AppColors.goldDark,
                          onTap: () {
                            Navigator.push(
                              context,
                              AppPageRoute(child: LeaderboardScreen()),
                            );
                          },
                        );
                      }

                      if (item == "bonus") {
                        return StreamBuilder<int>(
                          stream: _unviewedBonusStream,
                          builder: (context, snapshot) {
                            final unviewedCount = snapshot.data ?? 0;

                            return Stack(
                              fit: StackFit.expand,
                              children: [
                                CustomContainer(
                                  title: "bonus".tr(),
                                  icon: HugeIcons.strokeRoundedAward01,
                                  color: AppColors.softGold,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      AppPageRoute(
                                        child: const UserBonusScreen(),
                                      ),
                                    );
                                  },
                                ),
                                if (unviewedCount > 0)
                                  Positioned(
                                    right: 8.w,
                                    top: 8.h,
                                    child: Container(
                                      padding: EdgeInsets.all(6.r),
                                      decoration: const BoxDecoration(
                                        color: AppColors.heartRed,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Color(0x66DC3545),
                                            blurRadius: 8,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        "$unviewedCount",
                                        style: GoogleFonts.cairo(
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

                      if (item == "profile") {
                        return CustomContainer(
                          title: "profile".tr(),
                          icon: HugeIcons.strokeRoundedUser02,
                          color: AppColors.goldLight,
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
                        color: Colors.purple.shade400,
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

                SizedBox(height: 16.h),
                Divider(color: borderColor),
                SizedBox(height: 8.h),

                SectionHeader(title: "egtma3na_posts".tr()),

                SizedBox(height: 12.h),

                /// POSTS
                StreamBuilder<QuerySnapshot>(
                  stream: _postsStream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const LoadingState();
                    }

                    final posts = snapshot.data!.docs;

                    if (posts.isEmpty) {
                      return EmptyState(
                        title: "no_posts_found".tr(),
                        hugeIcon: HugeIcons.strokeRoundedFileCorrupt,
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: posts.length,
                      separatorBuilder: (_, __) => SizedBox(height: 12.h),
                      itemBuilder: (context, index) {
                        final post = posts[index];
                        final data = post.data() as Map<String, dynamic>;
                        final text = data["text"] ?? "";
                        final Map likes = data["likes"] ?? {};
                        final isLiked = likes.containsKey(widget.uid);
                        final likeCount = likes.length;

                        final isArabic = _arabicRegex.hasMatch(text);

                        return PostContainer(
                          isArabic: isArabic,
                          isLiked: isLiked,
                          text: text,
                          user: widget.user,
                          uid: widget.uid,
                          likeCount: likeCount,
                          post: post,
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
