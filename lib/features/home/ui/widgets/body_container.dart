import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';
import 'package:platformexamapp/core/widgets/empty_state.dart';
import 'package:platformexamapp/core/widgets/loading_state.dart';
import 'package:platformexamapp/core/widgets/section_header.dart';
import 'package:platformexamapp/features/auth/data/models/user_data.dart';
import 'package:platformexamapp/features/home/ui/widgets/featured_hero_card.dart';
import 'package:platformexamapp/features/home/ui/widgets/post_container.dart';
import 'package:platformexamapp/features/home/ui/widgets/quick_action_bar.dart';
import 'package:platformexamapp/features/home/ui/widgets/student_progress_overview.dart';

class BodyContainer extends StatefulWidget {
  final String uid;
  final UserData user;
  final ValueChanged<int>? onNavigateToTab;

  const BodyContainer({
    super.key,
    required this.uid,
    required this.user,
    this.onNavigateToTab,
  });

  @override
  State<BodyContainer> createState() => _BodyContainerState();
}

class _BodyContainerState extends State<BodyContainer> {
  late final Stream<QuerySnapshot> _postsStream;
  static final RegExp _arabicRegex = RegExp(r'[\u0600-\u06FF]');

  @override
  void initState() {
    super.initState();
    _postsStream = FirebaseFirestore.instance
        .collection("posts")
        .orderBy("createdAt", descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.darkSurface
        : AppColors.warmIvory;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.slate200;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
      width: double.infinity,
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32.r),
          topRight: Radius.circular(32.r),
        ),
        border: Border(top: BorderSide(color: borderColor, width: 1)),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 1. FEATURED HERO CARD (Dynamic: Active Meeting / Available Exam / Daily Content)
            FeaturedHeroCard(
              user: widget.user,
              uid: widget.uid,
            ),

            SizedBox(height: 16.h),

            /// 2. STUDENT PROGRESS OVERVIEW
            StudentProgressOverview(
              user: widget.user,
              uid: widget.uid,
            ),

            SizedBox(height: 18.h),

            /// 3. QUICK ACTIONS BAR
            SectionHeader(title: "quick_access".tr()),
            SizedBox(height: 10.h),
            QuickActionBar(
              user: widget.user,
              uid: widget.uid,
              onNavigateToTab: widget.onNavigateToTab,
            ),

            SizedBox(height: 18.h),
            Divider(color: borderColor, height: 1),
            SizedBox(height: 14.h),

            /// 4. ANNOUNCEMENTS & POSTS FEED
            SectionHeader(title: "community_announcements".tr()),
            SizedBox(height: 12.h),

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
                  separatorBuilder: (_, __) => SizedBox(height: 14.h),
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
            SizedBox(height: 80.h), // Space for floating bottom nav
          ],
        ),
      ),
    );
  }
}
