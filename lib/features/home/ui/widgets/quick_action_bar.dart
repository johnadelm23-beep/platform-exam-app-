import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';
import 'package:platformexamapp/core/theme/app_page_route.dart';
import 'package:platformexamapp/features/admin/ui/dashboard.dart';
import 'package:platformexamapp/features/auth/data/models/user_data.dart';
import 'package:platformexamapp/features/bonus/ui/user_bonus_screen.dart';
import 'package:platformexamapp/features/exams/ui/exam_list_screen.dart';
import 'package:platformexamapp/features/home/ui/daily_content_screen.dart';
import 'package:platformexamapp/features/states/ui/states_screen.dart';

class QuickActionBar extends StatefulWidget {
  final UserData user;
  final String uid;
  final ValueChanged<int>? onNavigateToTab;

  const QuickActionBar({
    super.key,
    required this.user,
    required this.uid,
    this.onNavigateToTab,
  });

  @override
  State<QuickActionBar> createState() => _QuickActionBarState();
}

class _QuickActionBarState extends State<QuickActionBar> {
  late final Stream<int> _unattemptedExamsStream;
  late final Stream<int> _unviewedBonusStream;

  @override
  void initState() {
    super.initState();
    _unattemptedExamsStream = _getUnattemptedExamsCount();
    _unviewedBonusStream = _getUnviewedBonusCount();
  }

  Stream<int> _getUnattemptedExamsCount() {
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

  Stream<int> _getUnviewedBonusCount() {
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
    final hasDashboardAccess = widget.user.canAccessDashboard;

    return StreamBuilder<int>(
      stream: _unattemptedExamsStream,
      builder: (context, examSnap) {
        final unattemptedExams = examSnap.data ?? 0;

        return StreamBuilder<int>(
          stream: _unviewedBonusStream,
          builder: (context, bonusSnap) {
            final unviewedBonuses = bonusSnap.data ?? 0;

            final actions = <_ActionItem>[
              _ActionItem(
                title: "exams".tr(),
                icon: HugeIcons.strokeRoundedFile01,
                color: AppColors.accentTeal,
                badgeCount: unattemptedExams,
                onTap: () {
                  if (widget.onNavigateToTab != null) {
                    widget.onNavigateToTab!(1);
                  } else {
                    Navigator.push(
                      context,
                      AppPageRoute(child: ExamsScreen(user: widget.user)),
                    );
                  }
                },
              ),
              _ActionItem(
                title: "todays_material".tr(),
                icon: HugeIcons.strokeRoundedFileBookmark,
                color: AppColors.classicNavy,
                onTap: () => Navigator.push(
                  context,
                  AppPageRoute(child: const DailyContentScreen()),
                ),
              ),
              _ActionItem(
                title: "bonus".tr(),
                icon: HugeIcons.strokeRoundedAward01,
                color: AppColors.softGold,
                badgeCount: unviewedBonuses,
                onTap: () => Navigator.push(
                  context,
                  AppPageRoute(child: const UserBonusScreen()),
                ),
              ),
              _ActionItem(
                title: "results".tr(),
                icon: HugeIcons.strokeRoundedChart01,
                color: AppColors.goldDark,
                onTap: () {
                  if (widget.onNavigateToTab != null) {
                    widget.onNavigateToTab!(2);
                  } else {
                    Navigator.push(
                      context,
                      AppPageRoute(child: LeaderboardScreen()),
                    );
                  }
                },
              ),
              if (hasDashboardAccess)
                _ActionItem(
                  title: "dashboard".tr(),
                  icon: HugeIcons.strokeRoundedSettings01,
                  color: AppColors.classicNavy,
                  isHighlighted: true,
                  onTap: () => Navigator.push(
                    context,
                    AppPageRoute(
                      child: AdminDashboardScreen(user: widget.user),
                    ),
                  ),
                ),
            ];

            return SizedBox(
              height: 96.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 2.w),
                itemCount: actions.length,
                separatorBuilder: (_, __) => SizedBox(width: 10.w),
                itemBuilder: (context, index) {
                  final action = actions[index];
                  return _buildActionCard(context, action, isDark);
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    _ActionItem action,
    bool isDark,
  ) {
    final cardBg = action.isHighlighted
        ? (isDark ? AppColors.classicNavy : const Color(0xFF1E355B))
        : (isDark ? AppColors.darkSurface : Colors.white);
    final borderColor = action.isHighlighted
        ? AppColors.softGold.withValues(alpha: 0.5)
        : (isDark ? AppColors.darkBorder : AppColors.slate200);
    final textColor = action.isHighlighted
        ? Colors.white
        : (isDark ? AppColors.darkTextMain : AppColors.classicNavy);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(18.r),
        child: Container(
          width: 104.w,
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: borderColor, width: 1.2),
            boxShadow: action.isHighlighted
                ? [
                    BoxShadow(
                      color: AppColors.classicNavy.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : isDark
                ? []
                : [
                    BoxShadow(
                      color: AppColors.classicNavy.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 40.r,
                    height: 40.r,
                    decoration: BoxDecoration(
                      color: action.isHighlighted
                          ? AppColors.softGold.withValues(alpha: 0.2)
                          : action.color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: HugeIcon(
                        icon: action.icon,
                        size: 20.r,
                        color: action.isHighlighted
                            ? AppColors.softGold
                            : action.color,
                      ),
                    ),
                  ),
                  if (action.badgeCount > 0)
                    Positioned(
                      top: -2.h,
                      right: -4.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 5.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.heartRed,
                          borderRadius: BorderRadius.circular(10.r),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x66DC3545),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          "${action.badgeCount}",
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 6.h),
              Text(
                action.title,
                style: GoogleFonts.cairo(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionItem {
  final String title;
  final dynamic icon;
  final Color color;
  final int badgeCount;
  final bool isHighlighted;
  final VoidCallback onTap;

  _ActionItem({
    required this.title,
    required this.icon,
    required this.color,
    this.badgeCount = 0,
    this.isHighlighted = false,
    required this.onTap,
  });
}
