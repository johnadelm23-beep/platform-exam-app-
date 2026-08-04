import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:platformexamapp/features/admin/ui/widgets/animated_counter.dart';

class StatisticsDashboardWidget extends StatelessWidget {
  final int totalUsers;
  final int activeUsers;
  final int needFollowUp;
  final int urgentCases;
  final int callsCompleted;
  final int visitsCompleted;

  const StatisticsDashboardWidget({
    super.key,
    required this.totalUsers,
    required this.activeUsers,
    required this.needFollowUp,
    required this.urgentCases,
    required this.callsCompleted,
    required this.visitsCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
        childAspectRatio: 1.45,
        children: [
          _buildStatCard(
            title: "Total Users",
            count: totalUsers,
            icon: HugeIcons.strokeRoundedUserGroup,
            gradientColors: [const Color(0xFF3A7BD5), const Color(0xFF3A6073)],
            isDark: isDark,
          ),
          _buildStatCard(
            title: "Active Users",
            count: activeUsers,
            icon: HugeIcons.strokeRoundedFire,
            gradientColors: [const Color(0xFF11998E), const Color(0xFF38EF7D)],
            isDark: isDark,
          ),
          _buildStatCard(
            title: "Need Follow-up",
            count: needFollowUp,
            icon: HugeIcons.strokeRoundedAlert02,
            gradientColors: [const Color(0xFFFF9966), const Color(0xFFFF5E62)],
            isDark: isDark,
          ),
          _buildStatCard(
            title: "Urgent Cases",
            count: urgentCases,
            icon: HugeIcons.strokeRoundedFlag01,
            gradientColors: [const Color(0xFFCB2D3E), const Color(0xFFEF473A)],
            isDark: isDark,
          ),
          _buildStatCard(
            title: "Calls Completed",
            count: callsCompleted,
            icon: HugeIcons.strokeRoundedCall,
            gradientColors: [const Color(0xFF4776E6), const Color(0xFF8E54E9)],
            isDark: isDark,
          ),
          _buildStatCard(
            title: "Visits Completed",
            count: visitsCompleted,
            icon: HugeIcons.strokeRoundedHome01,
            gradientColors: [const Color(0xFF130CB7), const Color(0xFF52E5E7)],
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required int count,
    required List<List<dynamic>> icon,
    required List<Color> gradientColors,
    required bool isDark,
  }) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withOpacity(0.35),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: HugeIcon(
                  icon: icon,
                  color: Colors.white,
                  size: 20.r,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          AnimatedCounter(
            value: count,
            style: TextStyle(
              color: Colors.white,
              fontSize: 26.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
