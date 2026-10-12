import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';
import 'package:platformexamapp/core/theme/app_page_route.dart';
import 'package:platformexamapp/features/admin/ui/add_exam_screen.dart';
import 'package:platformexamapp/features/admin/ui/add_post_screen.dart';
import 'package:platformexamapp/features/admin/ui/states_screen.dart';
import 'package:platformexamapp/features/admin/ui/top_user_interact.dart';
import 'package:platformexamapp/features/admin/ui/users_screen.dart';
import 'package:platformexamapp/features/auth/data/models/user_data.dart';
import 'package:platformexamapp/features/admin/ui/scanner_screen.dart';
import 'package:platformexamapp/features/admin/ui/events_screen.dart';
import 'package:platformexamapp/features/admin/ui/attendance_analytics_dashboard.dart';
import 'package:platformexamapp/features/admin/ui/daily_content_management.dart';
import 'package:platformexamapp/features/admin/ui/daily_content_history.dart';
import 'package:platformexamapp/features/admin/ui/seasons_management.dart';
import 'package:platformexamapp/features/admin/ui/admin_follow_up_screen.dart';
import 'package:platformexamapp/features/admin/ui/admin_bonus_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key, required this.user});
  final UserData user;

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Stream<int>? _totalUsersStream;
  Stream<int>? _totalExamsStream;
  Stream<int>? _activeEventsStream;
  Stream<int>? _completedAttemptsStream;

  @override
  void initState() {
    super.initState();
    if (widget.user.canAccessDashboard) {
      _totalUsersStream = FirebaseFirestore.instance
          .collection("users")
          .snapshots()
          .map((snap) => snap.docs.length);

      _totalExamsStream = FirebaseFirestore.instance
          .collection("exams")
          .snapshots()
          .map((snap) => snap.docs.length);

      _activeEventsStream = FirebaseFirestore.instance
          .collection("events")
          .where("isActive", isEqualTo: true)
          .snapshots()
          .map((snap) => snap.docs.length);

      _completedAttemptsStream = FirebaseFirestore.instance
          .collection("examAttempts")
          .where("done", isEqualTo: true)
          .snapshots()
          .map((snap) => snap.docs.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageBg = isDark ? AppColors.darkPageBg : AppColors.warmIvory;
    final textColor = isDark ? AppColors.darkTextMain : AppColors.classicNavy;

    if (!widget.user.canAccessDashboard) {
      return Scaffold(
        backgroundColor: pageBg,
        appBar: AppBar(
          title: Text(
            "access_denied".tr() == "access_denied"
                ? "Access Denied"
                : "access_denied".tr(),
            style: GoogleFonts.cairo(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: pageBg,
          elevation: 0,
        ),
        body: Center(
          child: Text(
            "no_permission_dashboard".tr() == "no_permission_dashboard"
                ? "You do not have permission to access the Dashboard."
                : "no_permission_dashboard".tr(),
            style: GoogleFonts.cairo(color: textColor, fontSize: 16.sp),
          ),
        ),
      );
    }

    final attendanceItems = <_DashboardAction>[
      if (widget.user.canAccessScanner)
        _DashboardAction(
          title: "attendance_scanner".tr(),
          subtitle: "scanner_desc".tr(),
          icon: HugeIcons.strokeRoundedQrCode,
          color: AppColors.accentTeal,
          onTap: () => Navigator.push(
            context,
            AppPageRoute(child: const ScannerScreen()),
          ),
        ),
      if (widget.user.canAccessFollowUp)
        _DashboardAction(
          title: "Follow Up",
          subtitle: "followup_desc".tr(),
          icon: HugeIcons.strokeRoundedCustomerSupport,
          color: Colors.deepOrange.shade400,
          onTap: () => Navigator.push(
            context,
            AppPageRoute(child: const AdminFollowUpScreen()),
          ),
        ),
      if (widget.user.canAccessAttendanceState)
        _DashboardAction(
          title: "attendance_stats".tr(),
          subtitle: "analytics_desc".tr(),
          icon: HugeIcons.strokeRoundedChart01,
          color: AppColors.softGold,
          onTap: () => Navigator.push(
            context,
            AppPageRoute(
              child: AttendanceAnalyticsDashboard(user: widget.user),
            ),
          ),
        ),
    ];

    final examItems = <_DashboardAction>[
      if (widget.user.canCreateExam)
        _DashboardAction(
          title: "add_exam".tr(),
          subtitle: "add_exam_desc".tr(),
          icon: HugeIcons.strokeRoundedAdd01,
          color: AppColors.successGreen,
          onTap: () => Navigator.push(
            context,
            AppPageRoute(child: const AddExamScreen()),
          ),
        ),
      if (widget.user.canAccessGradeStates)
        _DashboardAction(
          title: "stats".tr(),
          subtitle: "grades_desc".tr(),
          icon: HugeIcons.strokeRoundedAnalytics01,
          color: Colors.purple.shade400,
          onTap: () => Navigator.push(
            context,
            AppPageRoute(
              child: ScoresStatisticsScreen(user: widget.user),
            ),
          ),
        ),
      if (widget.user.canCreateContent)
        _DashboardAction(
          title: "daily_content_manager".tr(),
          subtitle: "daily_content_desc".tr(),
          icon: HugeIcons.strokeRoundedFileBookmark,
          color: Colors.teal.shade400,
          onTap: () => Navigator.push(
            context,
            AppPageRoute(
              child: const DailyContentManagementScreen(),
            ),
          ),
        ),
      if (widget.user.canAccessContentHistory)
        _DashboardAction(
          title: "content_history".tr(),
          subtitle: "content_history_desc".tr(),
          icon: HugeIcons.strokeRoundedFile01,
          color: Colors.brown.shade400,
          onTap: () => Navigator.push(
            context,
            AppPageRoute(
              child: DailyContentHistoryScreen(user: widget.user),
            ),
          ),
        ),
    ];

    final communityItems = <_DashboardAction>[
      if (widget.user.canCreatePost)
        _DashboardAction(
          title: "add_post".tr(),
          subtitle: "add_post_desc".tr(),
          icon: HugeIcons.strokeRoundedBookmark01,
          color: AppColors.goldDark,
          onTap: () => Navigator.push(
            context,
            AppPageRoute(child: const AddPostScreen()),
          ),
        ),
      if (widget.user.canAccessTopInteractions)
        _DashboardAction(
          title: "top_interactions".tr(),
          subtitle: "top_interactions_desc".tr(),
          icon: HugeIcons.strokeRoundedFavourite,
          color: AppColors.heartRed,
          onTap: () => Navigator.push(
            context,
            AppPageRoute(child: TopUsersScreen(user: widget.user)),
          ),
        ),
      if (widget.user.canManageBonus)
        _DashboardAction(
          title: "bonus_management".tr(),
          subtitle: "bonus_desc".tr(),
          icon: HugeIcons.strokeRoundedAward01,
          color: AppColors.softGold,
          onTap: () => Navigator.push(
            context,
            AppPageRoute(
              child: AdminBonusScreen(user: widget.user),
            ),
          ),
        ),
    ];

    final systemItems = <_DashboardAction>[
      if (widget.user.canAccessUsers)
        _DashboardAction(
          title: "users".tr(),
          subtitle: "users_desc".tr(),
          icon: HugeIcons.strokeRoundedUser,
          color: AppColors.classicNavy,
          onTap: () => Navigator.push(
            context,
            AppPageRoute(child: const UsersScreen()),
          ),
        ),
      if (widget.user.canManageEvents)
        _DashboardAction(
          title: "events_manager".tr(),
          subtitle: "events_desc".tr(),
          icon: HugeIcons.strokeRoundedCalendar01,
          color: Colors.orange.shade400,
          onTap: () => Navigator.push(
            context,
            AppPageRoute(child: const EventsManagementScreen()),
          ),
        ),
      if (widget.user.canManageSeasons)
        _DashboardAction(
          title: "seasons_manager".tr(),
          subtitle: "seasons_desc".tr(),
          icon: HugeIcons.strokeRoundedGrid,
          color: Colors.blueGrey.shade400,
          onTap: () => Navigator.push(
            context,
            AppPageRoute(
              child: const SeasonsManagementScreen(),
            ),
          ),
        ),
    ];

    return Scaffold(
      backgroundColor: pageBg,
      body: SafeArea(
        child: Column(
          children: [
            /// 1. APP BAR / HEADER
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: EdgeInsets.all(9.r),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.slate200,
                        ),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
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
                          "admin_command_center".tr(),
                          style: GoogleFonts.cairo(
                            fontSize: 19.sp,
                            color: textColor,
                            fontWeight: FontWeight.w900,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          widget.user.isAdminVal
                              ? "admin_full_privileges".tr()
                              : "sub_admin_access".tr(),
                          style: GoogleFonts.cairo(
                            fontSize: 11.sp,
                            color: widget.user.isAdminVal
                                ? AppColors.accentTeal
                                : AppColors.softGold,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: (widget.user.isAdminVal
                              ? AppColors.accentTeal
                              : AppColors.softGold)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: (widget.user.isAdminVal
                                ? AppColors.accentTeal
                                : AppColors.softGold)
                            .withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      widget.user.isAdminVal
                          ? "role_admin".tr()
                          : "role_sub_admin".tr(),
                      style: GoogleFonts.cairo(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w900,
                        color: widget.user.isAdminVal
                            ? AppColors.accentTeal
                            : AppColors.goldDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            /// 2. MAIN SCROLLABLE DASHBOARD BODY
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// KPI OVERVIEW METRICS
                    _buildKpiSection(isDark),

                    SizedBox(height: 20.h),

                    /// SECTION 1: ATTENDANCE & PASTORAL
                    if (attendanceItems.isNotEmpty) ...[
                      _buildSectionHeader(
                        title: "attendance_and_pastoral".tr(),
                        icon: HugeIcons.strokeRoundedQrCode,
                        iconColor: AppColors.accentTeal,
                        textColor: textColor,
                      ),
                      SizedBox(height: 10.h),
                      _buildActionGrid(attendanceItems, isDark),
                      SizedBox(height: 20.h),
                    ],

                    /// SECTION 2: EXAMS & EDUCATION
                    if (examItems.isNotEmpty) ...[
                      _buildSectionHeader(
                        title: "exams_and_curriculum".tr(),
                        icon: HugeIcons.strokeRoundedFile01,
                        iconColor: AppColors.classicNavy,
                        textColor: textColor,
                      ),
                      SizedBox(height: 10.h),
                      _buildActionGrid(examItems, isDark),
                      SizedBox(height: 20.h),
                    ],

                    /// SECTION 3: COMMUNITY & ENGAGEMENT
                    if (communityItems.isNotEmpty) ...[
                      _buildSectionHeader(
                        title: "community_engagement".tr(),
                        icon: HugeIcons.strokeRoundedBookmark01,
                        iconColor: AppColors.softGold,
                        textColor: textColor,
                      ),
                      SizedBox(height: 10.h),
                      _buildActionGrid(communityItems, isDark),
                      SizedBox(height: 20.h),
                    ],

                    /// SECTION 4: SYSTEM & ADMINISTRATION
                    if (systemItems.isNotEmpty) ...[
                      _buildSectionHeader(
                        title: "system_administration".tr(),
                        icon: HugeIcons.strokeRoundedSettings01,
                        iconColor: AppColors.classicNavy,
                        textColor: textColor,
                      ),
                      SizedBox(height: 10.h),
                      _buildActionGrid(systemItems, isDark),
                      SizedBox(height: 24.h),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedAnalytics01,
              size: 16.r,
              color: AppColors.softGold,
            ),
            SizedBox(width: 8.w),
            Text(
              "kpi_total_users".tr(), // overview label
              style: GoogleFonts.cairo(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextMain : AppColors.classicNavy,
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        Row(
          children: [
            Expanded(
              child: _buildKpiCard(
                title: "kpi_total_users".tr(),
                stream: _totalUsersStream,
                icon: HugeIcons.strokeRoundedUser,
                color: AppColors.accentTeal,
                isDark: isDark,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _buildKpiCard(
                title: "kpi_total_exams".tr(),
                stream: _totalExamsStream,
                icon: HugeIcons.strokeRoundedFile01,
                color: AppColors.classicNavy,
                isDark: isDark,
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        Row(
          children: [
            Expanded(
              child: _buildKpiCard(
                title: "kpi_active_events".tr(),
                stream: _activeEventsStream,
                icon: HugeIcons.strokeRoundedCalendar01,
                color: AppColors.softGold,
                isDark: isDark,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _buildKpiCard(
                title: "kpi_attendance_records".tr(),
                stream: _completedAttemptsStream,
                icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                color: AppColors.successGreen,
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required String title,
    required Stream<int>? stream,
    required dynamic icon,
    required Color color,
    required bool isDark,
  }) {
    final cardBg = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.slate200;
    final textColor = isDark ? AppColors.darkTextMain : AppColors.classicNavy;
    final labelColor = isDark ? AppColors.darkTextCaption : AppColors.slate500;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: AppColors.classicNavy.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: HugeIcon(icon: icon, size: 18.r, color: color),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StreamBuilder<int>(
                  stream: stream,
                  builder: (context, snapshot) {
                    final val = snapshot.data ?? 0;
                    return Text(
                      "$val",
                      style: GoogleFonts.cairo(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w900,
                        color: textColor,
                        height: 1.1,
                      ),
                    );
                  },
                ),
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: labelColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required dynamic icon,
    required Color iconColor,
    required Color textColor,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(6.r),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: HugeIcon(icon: icon, size: 16.r, color: iconColor),
        ),
        SizedBox(width: 8.w),
        Text(
          title,
          style: GoogleFonts.cairo(
            fontSize: 15.sp,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildActionGrid(List<_DashboardAction> actions, bool isDark) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      separatorBuilder: (_, __) => SizedBox(height: 8.h),
      itemBuilder: (context, index) {
        final item = actions[index];
        return _buildActionTile(item, isDark);
      },
    );
  }

  Widget _buildActionTile(_DashboardAction item, bool isDark) {
    final cardBg = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.slate200;
    final textColor = isDark ? AppColors.darkTextMain : AppColors.classicNavy;
    final subtitleColor =
        isDark ? AppColors.darkTextCaption : AppColors.slate500;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: AppColors.classicNavy.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            children: [
              Container(
                width: 44.r,
                height: 44.r,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Center(
                  child: HugeIcon(
                    icon: item.icon,
                    size: 22.r,
                    color: item.color,
                  ),
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: GoogleFonts.cairo(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.subtitle.isNotEmpty) ...[
                      SizedBox(height: 1.h),
                      Text(
                        item.subtitle,
                        style: GoogleFonts.cairo(
                          fontSize: 11.sp,
                          color: subtitleColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14.r,
                color: subtitleColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardAction {
  final String title;
  final String subtitle;
  final dynamic icon;
  final Color color;
  final VoidCallback onTap;

  _DashboardAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
