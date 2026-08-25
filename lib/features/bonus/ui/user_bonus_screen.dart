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

class UserBonusAggregate {
  final String userId;
  final String userName;
  double totalGranted;
  double totalSpent;
  final List<String> reasons;
  Timestamp? latestTimestamp;

  double get remaining => totalGranted - totalSpent;

  UserBonusAggregate({
    required this.userId,
    required this.userName,
    required this.totalGranted,
    required this.totalSpent,
    required this.reasons,
    this.latestTimestamp,
  });
}

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
    // Public recognition stream for all bonus records
    _bonusStream = FirebaseFirestore.instance.collection("bonuses").snapshots();

    // Mark current bonus notifications as viewed for current user
    _markBonusAsViewed();
  }

  Future<void> _markBonusAsViewed() async {
    if (_currentUid.isEmpty) return;
    try {
      await FirebaseFirestore.instance.collection("users").doc(_currentUid).set({
        "lastBonusViewed": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "bonus".tr(),
                          style: GoogleFonts.cairo(
                            fontSize: 22.sp,
                            color: textColor,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          "Honoring Outstanding Achievements 🏆",
                          style: GoogleFonts.cairo(
                            fontSize: 12.sp,
                            color: AppColors.softGold,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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

                    if (!snapshot.hasData && snapshot.connectionState == ConnectionState.waiting) {
                      return const LoadingState();
                    }

                    final docs = snapshot.data?.docs ?? [];

                    if (docs.isEmpty) {
                      return EmptyState(
                        title: "no_bonus_records".tr(),
                        hugeIcon: HugeIcons.strokeRoundedAward01,
                      );
                    }

                    // Process and aggregate bonus records by user
                    final Map<String, UserBonusAggregate> userMap = {};

                    for (var doc in docs) {
                      final data = doc.data() as Map<String, dynamic>? ?? {};
                      final uId = _parseString(data["userId"] ?? data["uid"] ?? data["user_id"] ?? data["id"]);
                      final uName = _parseString(data["userName"] ?? data["name"] ?? data["user_name"] ?? "Member");
                      final amt = _parseDouble(data["amount"] ?? data["points"] ?? data["bonus"]);
                      final spnt = _parseDouble(data["spent"] ?? data["spentAmount"] ?? data["spent_amount"]);
                      final reason = _parseString(data["reason"] ?? data["note"]);
                      final timestamp = _parseTimestamp(data["createdAt"]);

                      final effectiveKey = uId.isNotEmpty ? uId : (uName.isNotEmpty ? uName : doc.id);
                      final effectiveName = uName.isNotEmpty ? uName : "Member ($effectiveKey)";

                      if (!userMap.containsKey(effectiveKey)) {
                        userMap[effectiveKey] = UserBonusAggregate(
                          userId: effectiveKey,
                          userName: effectiveName,
                          totalGranted: 0.0,
                          totalSpent: 0.0,
                          reasons: [],
                          latestTimestamp: timestamp,
                        );
                      }

                      final userAgg = userMap[effectiveKey]!;
                      userAgg.totalGranted += amt;
                      userAgg.totalSpent += spnt;

                      if (reason.isNotEmpty && !userAgg.reasons.contains(reason)) {
                        userAgg.reasons.add(reason);
                      }

                      if (timestamp != null) {
                        if (userAgg.latestTimestamp == null ||
                            timestamp.compareTo(userAgg.latestTimestamp!) > 0) {
                          userAgg.latestTimestamp = timestamp;
                        }
                      }
                    }

                    final sortedUsers = userMap.values.toList()
                      ..sort((a, b) {
                        // 1. Primary Sort: Total Bonus Granted DESCENDING
                        if (a.totalGranted != b.totalGranted) {
                          return b.totalGranted.compareTo(a.totalGranted);
                        }
                        // 2. Secondary Sort: Remaining Bonus DESCENDING
                        if (a.remaining != b.remaining) {
                          return b.remaining.compareTo(a.remaining);
                        }
                        // 3. Tertiary Sort: User Name ASCENDING (deterministic tie-breaker)
                        return a.userName.compareTo(b.userName);
                      });

                    return ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      itemCount: sortedUsers.length,
                      separatorBuilder: (_, __) => SizedBox(height: 14.h),
                      itemBuilder: (context, index) {
                        final userAgg = sortedUsers[index];
                        final rank = index + 1;
                        final isMe = userAgg.userId == _currentUid;

                        Color rankBadgeColor;
                        if (rank == 1) {
                          rankBadgeColor = AppColors.softGold;
                        } else if (rank == 2) {
                          rankBadgeColor = const Color(0xFFC0C0C0);
                        } else if (rank == 3) {
                          rankBadgeColor = const Color(0xFFCD7F32);
                        } else {
                          rankBadgeColor = isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted;
                        }

                        final primaryReason = userAgg.reasons.isNotEmpty
                            ? userAgg.reasons.first
                            : "Outstanding Participation";

                        return GlassCard(
                          padding: EdgeInsets.all(16.r),
                          borderRadius: 20.r,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  /// Rank / Trophy Badge
                                  Container(
                                    width: 40.r,
                                    height: 40.r,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: rankBadgeColor.withOpacity(0.18),
                                      border: Border.all(
                                        color: rankBadgeColor,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Center(
                                      child: rank <= 3
                                          ? Icon(
                                              Icons.emoji_events_rounded,
                                              color: rankBadgeColor,
                                              size: 20.r,
                                            )
                                          : Text(
                                              "#$rank",
                                              style: GoogleFonts.cairo(
                                                color: textColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14.sp,
                                              ),
                                            ),
                                    ),
                                  ),
                                  SizedBox(width: 12.w),

                                  /// User Name (Public display ONLY, no email/phone)
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                userAgg.userName + (isMe ? " (You)" : ""),
                                                style: GoogleFonts.cairo(
                                                  fontSize: 16.sp,
                                                  fontWeight: FontWeight.w900,
                                                  color: textColor,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 2.h),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.star_rounded,
                                              color: AppColors.softGold,
                                              size: 14.r,
                                            ),
                                            SizedBox(width: 4.w),
                                            Expanded(
                                              child: Text(
                                                primaryReason,
                                                style: GoogleFonts.cairo(
                                                  fontSize: 12.sp,
                                                  color: AppColors.softGold,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: 12.h),
                              Divider(color: borderColor),
                              SizedBox(height: 8.h),

                              /// Stats Breakdown Row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  /// Total Bonus Granted
                                  _buildStatColumn(
                                    label: "total_bonus".tr(),
                                    value: _formatNumber(userAgg.totalGranted),
                                    color: AppColors.softGold,
                                    mutedColor: mutedColor,
                                  ),
                                  Container(
                                    width: 1.w,
                                    height: 24.h,
                                    color: borderColor,
                                  ),
                                  /// Total Spent
                                  _buildStatColumn(
                                    label: "total_spent".tr(),
                                    value: _formatNumber(userAgg.totalSpent),
                                    color: AppColors.heartRed,
                                    mutedColor: mutedColor,
                                  ),
                                  Container(
                                    width: 1.w,
                                    height: 24.h,
                                    color: borderColor,
                                  ),
                                  /// Remaining Bonus
                                  _buildStatColumn(
                                    label: "remaining_bonus".tr(),
                                    value: _formatNumber(userAgg.remaining),
                                    color: AppColors.successGreen,
                                    mutedColor: mutedColor,
                                  ),
                                ],
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

  Widget _buildStatColumn({
    required String label,
    required String value,
    required Color color,
    required Color mutedColor,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 11.sp,
            color: mutedColor,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          value,
          style: GoogleFonts.cairo(
            fontSize: 15.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  String _formatNumber(double val) {
    if (val.truncateToDouble() == val) {
      return val.truncate().toString();
    }
    return val.toStringAsFixed(1);
  }

  static double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val.trim()) ?? 0.0;
    return 0.0;
  }

  static String _parseString(dynamic val) {
    if (val == null) return "";
    return val.toString().trim();
  }

  static Timestamp? _parseTimestamp(dynamic val) {
    if (val is Timestamp) return val;
    if (val is String) {
      final dt = DateTime.tryParse(val.trim());
      if (dt != null) return Timestamp.fromDate(dt);
    }
    if (val is int) return Timestamp.fromMillisecondsSinceEpoch(val);
    return null;
  }
}
