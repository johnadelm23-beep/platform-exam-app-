import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';
import 'package:platformexamapp/core/widgets/empty_state.dart';
import 'package:platformexamapp/core/widgets/glass_card.dart';
import 'package:platformexamapp/core/widgets/loading_state.dart';

class UserBonusScreen extends StatefulWidget {
  const UserBonusScreen({super.key});

  @override
  State<UserBonusScreen> createState() => _UserBonusScreenState();
}

class _UserBonusScreenState extends State<UserBonusScreen> {
  late final Stream<QuerySnapshot> _bonusStream;
  final String _currentUid = FirebaseAuth.instance.currentUser?.uid ?? "";

  @override
  void initState() {
    super.initState();
    // Strictly fetch only the current user's bonus records for privacy & security compliance
    _bonusStream = FirebaseFirestore.instance
        .collection("bonuses")
        .where("userId", isEqualTo: _currentUid)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageBg = isDark ? AppColors.darkPageBg : AppColors.lightPageBg;
    final textColor = isDark ? AppColors.darkTextMain : AppColors.lightTextMain;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return Scaffold(
      backgroundColor: pageBg,
      body: SafeArea(
        child: Column(
          children: [
            /// Header Bar
            Padding(
              padding: EdgeInsets.all(16.r),
              child: Row(
                children: [
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
                  SizedBox(width: 12.w),
                  Text(
                    "bonus".tr(),
                    style: GoogleFonts.cairo(
                      fontSize: 22.sp,
                      color: textColor,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(32.r),
                  ),
                  border: Border(top: BorderSide(color: borderColor, width: 1)),
                ),
                child: StreamBuilder<QuerySnapshot>(
                  stream: _bonusStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          "error".tr(),
                          style: GoogleFonts.cairo(color: AppColors.heartRed),
                        ),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const LoadingState();
                    }

                    final docs = snapshot.data?.docs ?? [];

                    double myGranted = 0.0;
                    double mySpent = 0.0;

                    for (var doc in docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      final amount = (data["amount"] as num?)?.toDouble() ?? 0.0;
                      final spent = (data["spent"] as num?)?.toDouble() ?? 0.0;

                      myGranted += amount;
                      mySpent += spent;
                    }

                    final double myRemaining = myGranted - mySpent;

                    return CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        /// Personal Bonus Summary Card
                        SliverToBoxAdapter(
                          child: GlassCard(
                            padding: EdgeInsets.all(18.r),
                            borderRadius: 24.r,
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(12.r),
                                      decoration: BoxDecoration(
                                        color: AppColors.softGold.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: HugeIcon(
                                        icon: HugeIcons.strokeRoundedAward01,
                                        color: AppColors.softGold,
                                        size: 28.r,
                                      ),
                                    ),
                                    SizedBox(width: 14.w),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "my_profile".tr(),
                                            style: GoogleFonts.cairo(
                                              fontSize: 13.sp,
                                              color: mutedColor,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            "remaining_bonus".tr(),
                                            style: GoogleFonts.cairo(
                                              fontSize: 18.sp,
                                              fontWeight: FontWeight.w900,
                                              color: textColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 14.w,
                                        vertical: 8.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.softGold.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(16.r),
                                        border: Border.all(
                                          color: AppColors.softGold.withOpacity(0.4),
                                        ),
                                      ),
                                      child: Text(
                                        "${myRemaining.toStringAsFixed(myRemaining.truncateToDouble() == myRemaining ? 0 : 1)} pts",
                                        style: GoogleFonts.cairo(
                                          color: AppColors.softGold,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 18.sp,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16.h),
                                Divider(color: borderColor),
                                SizedBox(height: 12.h),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        children: [
                                          Text(
                                            "total_bonus".tr(),
                                            style: GoogleFonts.cairo(
                                              fontSize: 12.sp,
                                              color: mutedColor,
                                            ),
                                          ),
                                          SizedBox(height: 2.h),
                                          Text(
                                            "${myGranted.toStringAsFixed(myGranted.truncateToDouble() == myGranted ? 0 : 1)}",
                                            style: GoogleFonts.cairo(
                                              fontSize: 16.sp,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.successGreen,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      width: 1.w,
                                      height: 30.h,
                                      color: borderColor,
                                    ),
                                    Expanded(
                                      child: Column(
                                        children: [
                                          Text(
                                            "total_spent".tr(),
                                            style: GoogleFonts.cairo(
                                              fontSize: 12.sp,
                                              color: mutedColor,
                                            ),
                                          ),
                                          SizedBox(height: 2.h),
                                          Text(
                                            "${mySpent.toStringAsFixed(mySpent.truncateToDouble() == mySpent ? 0 : 1)}",
                                            style: GoogleFonts.cairo(
                                              fontSize: 16.sp,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.heartRed,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: 24.h).toSliver(),

                        /// Section Header: Transaction History
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.only(bottom: 12.h),
                            child: Text(
                              "meeting_history".tr(),
                              style: GoogleFonts.cairo(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ),
                        ),

                        /// Personal History Transactions
                        if (docs.isEmpty)
                          SliverToBoxAdapter(
                            child: EmptyState(
                              title: "no_bonus_records".tr(),
                              hugeIcon: HugeIcons.strokeRoundedAward01,
                            ),
                          )
                        else
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final doc = docs[index];
                                final data = doc.data() as Map<String, dynamic>;
                                final amount = (data["amount"] as num?)?.toDouble() ?? 0.0;
                                final spent = (data["spent"] as num?)?.toDouble() ?? 0.0;
                                final reason = (data["reason"] ?? "").toString();
                                final isGrant = amount > 0;

                                return Container(
                                  margin: EdgeInsets.only(bottom: 10.h),
                                  child: GlassCard(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16.w,
                                      vertical: 12.h,
                                    ),
                                    borderRadius: 18.r,
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(8.r),
                                          decoration: BoxDecoration(
                                            color: isGrant
                                                ? AppColors.successGreen.withOpacity(0.15)
                                                : AppColors.heartRed.withOpacity(0.15),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            isGrant
                                                ? Icons.arrow_upward_rounded
                                                : Icons.arrow_downward_rounded,
                                            color: isGrant
                                                ? AppColors.successGreen
                                                : AppColors.heartRed,
                                            size: 20.r,
                                          ),
                                        ),
                                        SizedBox(width: 12.w),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                isGrant ? "add_bonus".tr() : "record_spent".tr(),
                                                style: GoogleFonts.cairo(
                                                  fontSize: 14.sp,
                                                  fontWeight: FontWeight.bold,
                                                  color: textColor,
                                                ),
                                              ),
                                              if (reason.isNotEmpty)
                                                Text(
                                                  reason,
                                                  style: GoogleFonts.cairo(
                                                    fontSize: 12.sp,
                                                    color: mutedColor,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          isGrant
                                              ? "+${amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 1)}"
                                              : "-${spent.toStringAsFixed(spent.truncateToDouble() == spent ? 0 : 1)}",
                                          style: GoogleFonts.cairo(
                                            color: isGrant
                                                ? AppColors.successGreen
                                                : AppColors.heartRed,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 15.sp,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              childCount: docs.length,
                            ),
                          ),
                      ],
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

extension SizedBoxToSliver on SizedBox {
  Widget toSliver() => SliverToBoxAdapter(child: this);
}
