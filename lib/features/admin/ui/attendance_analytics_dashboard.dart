import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';
import 'package:platformexamapp/core/services/offline_sync_service.dart';
import 'package:platformexamapp/core/widgets/glass_card.dart';
import 'package:platformexamapp/features/admin/utils/admin_follow_up_helper.dart';
import 'package:platformexamapp/features/auth/data/models/user_data.dart';
import 'package:platformexamapp/core/widgets/app_dialog.dart';

class AttendanceAnalyticsDashboard extends StatefulWidget {
  const AttendanceAnalyticsDashboard({super.key, this.user});
  final UserData? user;

  @override
  State<AttendanceAnalyticsDashboard> createState() =>
      _AttendanceAnalyticsDashboardState();
}

class _AttendanceAnalyticsDashboardState
    extends State<AttendanceAnalyticsDashboard> {
  String? _selectedSeasonId;
  late Future<Map<String, dynamic>> _statsFuture;
  late final Stream<QuerySnapshot> _seasonsStream;

  @override
  void initState() {
    super.initState();
    _seasonsStream = FirebaseFirestore.instance
        .collection("seasons")
        .orderBy("createdAt", descending: true)
        .snapshots();
    _statsFuture = _calculateDashboardStats();
  }

  void _confirmResetAttendance(BuildContext context) {
    if (widget.user?.isAdmin != true) return;
    AppDialog.show(
      context: context,
      icon: Icons.warning_amber_rounded,
      iconColor: AppColors.softGold,
      title: "Reset Attendance",
      description:
          "This will permanently delete all attendance logs, streaks, and statistics. Student accounts will remain intact. This action cannot be undone. Are you sure?",
      confirmText: "Reset",
      confirmButtonColor: AppColors.heartRed,
      cancelText: "Cancel",
      onConfirm: () async {
        Navigator.pop(context); // Pop confirm dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(
            child: CircularProgressIndicator(color: AppColors.softGold),
          ),
        );

        try {
          await OfflineSyncService.resetAttendanceData();
          if (mounted) {
            Navigator.pop(context); // Pop loading
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Attendance reset successfully!"),
                backgroundColor: Colors.green,
              ),
            );
            setState(() {
              _statsFuture = _calculateDashboardStats();
            });
          }
        } catch (e) {
          if (mounted) {
            Navigator.pop(context); // Pop loading
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Reset failed: $e"),
                backgroundColor: AppColors.heartRed,
              ),
            );
          }
        }
      },
      onCancel: () => Navigator.pop(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageBg = isDark ? AppColors.darkPageBg : AppColors.lightPageBg;
    final surfaceColor = isDark
        ? AppColors.darkSurface
        : AppColors.lightSurface;
    final cardBg = isDark
        ? AppColors.darkGlassSurface
        : AppColors.lightGlassSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.darkTextMain : AppColors.lightTextMain;
    final mutedColor = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: pageBg,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: textColor,
            size: 20.r,
          ),
        ),
        title: Text(
          "attendance_dashboard".tr(),
          style: GoogleFonts.cairo(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
        ),
        centerTitle: true,
        actions: [
          if (widget.user?.isAdmin == true)
            IconButton(
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedDelete01,
                color: AppColors.heartRed,
                size: 20.r,
              ),
              tooltip: "Reset Attendance Data",
              onPressed: () => _confirmResetAttendance(context),
            ),
        ],
      ),
      body: Container(
        margin: EdgeInsets.only(top: 10.h),
        width: double.infinity,
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32.r),
            topRight: Radius.circular(32.r),
          ),
          border: Border(top: BorderSide(color: borderColor, width: 1)),
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: StreamBuilder<QuerySnapshot>(
                stream: _seasonsStream,
                builder: (context, seasonSnapshot) {
                  final seasons = seasonSnapshot.data?.docs ?? [];
                  return DropdownButtonFormField<String>(
                    value: _selectedSeasonId,
                    dropdownColor: surfaceColor,
                    style: GoogleFonts.cairo(
                      color: textColor,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      labelText: "Selected Season",
                      labelStyle: GoogleFonts.cairo(color: AppColors.softGold),
                      fillColor: cardBg,
                      filled: true,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.r),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.r),
                        borderSide: const BorderSide(
                          color: AppColors.softGold,
                          width: 1.5,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.r),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                    ),
                    items: seasons.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final name = data["name"] ?? "Season";
                      final isActive = data["status"] == "active";
                      return DropdownMenuItem<String>(
                        value: doc.id,
                        child: Text(
                          name + (isActive ? " (Active)" : ""),
                          style: GoogleFonts.cairo(
                            color: textColor,
                            fontWeight: isActive
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedSeasonId = val;
                        _statsFuture = _calculateDashboardStats();
                      });
                    },
                  );
                },
              ),
            ),
            Expanded(
              child: FutureBuilder<Map<String, dynamic>>(
                future: _statsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.softGold,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.r),
                        child: Text(
                          "Error loading stats: ${snapshot.error}",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(color: AppColors.heartRed),
                        ),
                      ),
                    );
                  }

                  final stats = snapshot.data ?? {};
                  final totalUsers = stats["totalUsers"] as int;
                  final todayAttendance = stats["todayAttendance"] as int;
                  final absentToday = stats["absentToday"] as int;
                  final avgAttendance = stats["avgAttendance"] as double;
                  final activeEventTitle = stats["activeEventTitle"] as String;
                  final topUsers = stats["topUsers"] as List<UserData>;
                  final lowestUsers = stats["lowestUsers"] as List<UserData>;
                  final weeklyData = stats["weeklyData"] as Map<int, int>;
                  final monthlyData = stats["monthlyData"] as Map<int, int>;
                  final heatmapData = stats["heatmapData"] as Map<String, int>;

                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.all(16.r),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Active Event Summary
                        _buildSectionHeader(
                          "current_active_event".tr(),
                          context,
                        ),
                        GlassCard(
                          child: ListTile(
                            leading: Container(
                              padding: EdgeInsets.all(8.r),
                              decoration: BoxDecoration(
                                color: AppColors.softGold.withValues(
                                  alpha: 0.15,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: HugeIcon(
                                icon: HugeIcons.strokeRoundedCalendar01,
                                color: AppColors.softGold,
                                size: 22.r,
                              ),
                            ),
                            title: Text(
                              activeEventTitle,
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.bold,
                                fontSize: 15.sp,
                                color: textColor,
                              ),
                            ),
                            subtitle: Text(
                              "gate_for_scan".tr(),
                              style: GoogleFonts.cairo(
                                fontSize: 12.sp,
                                color: mutedColor,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 20.h),

                        // Stats Grid Cards
                        _buildSectionHeader("key_statistice".tr(), context),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 10.w,
                          mainAxisSpacing: 10.h,
                          childAspectRatio: 1.5,
                          children: [
                            _buildStatCard(
                              context,
                              "total_users".tr(),
                              "$totalUsers",
                              Colors.blue,
                              HugeIcons.strokeRoundedUser02,
                            ),
                            _buildStatCard(
                              context,
                              "present_today".tr(),
                              "$todayAttendance",
                              Colors.green,
                              Icons.person_add,
                            ),
                            _buildStatCard(
                              context,
                              "absent_today".tr(),
                              "$absentToday",
                              AppColors.heartRed,
                              Icons.person_remove,
                            ),
                            _buildStatCard(
                              context,
                              "avg_atten".tr(),
                              "${avgAttendance.toStringAsFixed(1)}%",
                              Colors.purple,
                              HugeIcons.strokeRoundedActivity01,
                            ),
                          ],
                        ),
                        SizedBox(height: 24.h),

                        // Weekly Graph (Bar Chart)
                        _buildSectionHeader("weekly_atten_trend".tr(), context),
                        _buildWeeklyBarChart(context, weeklyData),
                        SizedBox(height: 24.h),

                        // Monthly Graph (Line Chart)
                        _buildSectionHeader("monthly_statistics".tr(), context),
                        _buildMonthlyLineChart(context, monthlyData),
                        SizedBox(height: 24.h),

                        // Density Heatmap
                        _buildSectionHeader("attent_heatmap".tr(), context),
                        _buildHeatmapGrid(context, heatmapData),
                        SizedBox(height: 24.h),

                        // Top Users List (All Members)
                        _buildSectionHeader(
                          "All Members Attendance Ranking",
                          context,
                        ),

                        _buildUsersListView(context, topUsers),
                        SizedBox(height: 24.h),

                        // Lowest Attendance List
                        _buildSectionHeader("needs_attention".tr(), context),
                        _buildUsersListView(
                          context,
                          lowestUsers,
                          isLowest: true,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextMain : AppColors.lightTextMain;

    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Text(
        title,
        style: GoogleFonts.cairo(
          fontSize: 16.sp,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String val,
    Color color,
    dynamic icon,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextMain : AppColors.lightTextMain;
    final mutedColor = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;

    return GlassCard(
      padding: EdgeInsets.all(12.r),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: icon is IconData
                ? Icon(icon as IconData, color: color, size: 22.r)
                : icon is List<List<dynamic>>
                ? HugeIcon(
                    icon: icon as List<List<dynamic>>,
                    color: color,
                    size: 22.r,
                  )
                : Icon(Icons.star, color: color, size: 22.r),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: GoogleFonts.cairo(fontSize: 11.sp, color: mutedColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  val,
                  style: GoogleFonts.cairo(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyBarChart(BuildContext context, Map<int, int> data) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;
    final days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    List<BarChartGroupData> barGroups = [];

    for (int i = 1; i <= 7; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: (data[i] ?? 0).toDouble(),
              color: AppColors.softGold,
              width: 14.r,
              borderRadius: BorderRadius.circular(4.r),
            ),
          ],
        ),
      );
    }

    return GlassCard(
      padding: EdgeInsets.all(12.r),
      child: SizedBox(
        height: 200.h,
        width: double.infinity,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: 20,
            barTouchData: BarTouchData(enabled: true),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (double value, TitleMeta meta) {
                    int dayIndex = value.toInt() - 1;
                    if (dayIndex >= 0 && dayIndex < 7) {
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text(
                          days[dayIndex],
                          style: GoogleFonts.cairo(
                            fontSize: 10.sp,
                            color: mutedColor,
                          ),
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            barGroups: barGroups,
          ),
        ),
      ),
    );
  }

  Widget _buildMonthlyLineChart(BuildContext context, Map<int, int> data) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;
    final List<String> monthNames = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    List<FlSpot> spots = [];

    for (int i = 1; i <= 12; i++) {
      spots.add(FlSpot(i.toDouble(), (data[i] ?? 0).toDouble()));
    }

    return GlassCard(
      padding: EdgeInsets.all(12.r),
      child: SizedBox(
        height: 200.h,
        width: double.infinity,
        child: LineChart(
          LineChartData(
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 2,
                  getTitlesWidget: (double value, TitleMeta meta) {
                    int idx = value.toInt() - 1;
                    if (idx >= 0 && idx < 12) {
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text(
                          monthNames[idx],
                          style: GoogleFonts.cairo(
                            fontSize: 10.sp,
                            color: mutedColor,
                          ),
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: AppColors.softGold,
                barWidth: 3.r,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  color: AppColors.softGold.withValues(alpha: 0.15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeatmapGrid(BuildContext context, Map<String, int> heatmap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final emptyCellColor = isDark
        ? AppColors.darkGlassSurface
        : AppColors.lightGlassSurface;
    final now = DateTime.now();
    List<Widget> gridItems = [];

    for (int i = 27; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey =
          "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      final count = heatmap[dateKey] ?? 0;

      Color cellColor = emptyCellColor;
      if (count > 0 && count <= 2) {
        cellColor = AppColors.softGold.withValues(alpha: 0.3);
      } else if (count > 2 && count <= 5) {
        cellColor = AppColors.softGold.withValues(alpha: 0.6);
      } else if (count > 5) {
        cellColor = AppColors.softGold;
      }

      gridItems.add(
        Tooltip(
          message: "$dateKey: $count attending",
          child: Container(
            decoration: BoxDecoration(
              color: cellColor,
              borderRadius: BorderRadius.circular(6.r),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Center(
              child: Text(
                "${date.day}",
                style: GoogleFonts.cairo(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                  color: count > 2
                      ? Colors.black87
                      : (isDark
                            ? AppColors.darkTextMain
                            : AppColors.lightTextMain),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return GlassCard(
      padding: EdgeInsets.all(12.r),
      child: GridView.count(
        crossAxisCount: 7,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 6.w,
        mainAxisSpacing: 6.h,
        childAspectRatio: 1.2,
        children: gridItems,
      ),
    );
  }

  Widget _buildUsersListView(
    BuildContext context,
    List<UserData> users, {
    bool isLowest = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextMain : AppColors.lightTextMain;
    final mutedColor = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    if (users.isEmpty) {
      return GlassCard(
        padding: EdgeInsets.all(16.r),
        child: Text(
          "No user statistics compiled yet.",
          style: GoogleFonts.cairo(color: mutedColor),
          textAlign: TextAlign.center,
        ),
      );
    }

    final accentColor = isLowest ? AppColors.heartRed : AppColors.softGold;

    return GlassCard(
      padding: EdgeInsets.zero,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: users.length,
        separatorBuilder: (_, __) => Divider(color: borderColor, height: 1),
        itemBuilder: (context, index) {
          final user = users[index];
          return ListTile(
            contentPadding: EdgeInsets.symmetric(
              horizontal: 14.w,
              vertical: 4.h,
            ),
            leading: Container(
              width: 34.r,
              height: 34.r,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: accentColor.withValues(alpha: 0.4)),
              ),
              child: Center(
                child: Text(
                  "${index + 1}",
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.sp,
                    color: accentColor,
                  ),
                ),
              ),
            ),
            title: Text(
              user.name ?? "User",
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold,
                fontSize: 14.sp,
                color: textColor,
              ),
            ),
            subtitle: Text(
              user.humanReadableId ?? "",
              style: GoogleFonts.cairo(fontSize: 12.sp, color: mutedColor),
            ),
            trailing: Text(
              "${user.attendancePercentage ?? 0.0}%",
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.w900,
                fontSize: 15.sp,
                color: accentColor,
              ),
            ),
          );
        },
      ),
    );
  }

  Future<Map<String, dynamic>> _calculateDashboardStats() async {
    final Map<String, dynamic> result = {};

    try {
      String seasonId = _selectedSeasonId ?? "";
      if (seasonId.isEmpty) {
        seasonId = await OfflineSyncService.getActiveSeasonId();
        _selectedSeasonId = seasonId;
      }

      // 1. Total Users count
      final usersSnap = await FirebaseFirestore.instance
          .collection("users")
          .get();
      final totalUsers = usersSnap.docs.length;

      // 2. Active Event details in this season
      final activeEventSnap = await FirebaseFirestore.instance
          .collection("events")
          .where("isActive", isEqualTo: true)
          .where("seasonId", isEqualTo: seasonId)
          .limit(1)
          .get();

      String activeEventId = "";
      String activeEventTitle = "No Active Event";
      if (activeEventSnap.docs.isNotEmpty) {
        activeEventId = activeEventSnap.docs.first.id;
        activeEventTitle =
            activeEventSnap.docs.first["title"] ?? "Active Event";
      }
      result["activeEventTitle"] = activeEventTitle;

      // 3. Today's Attendance count
      int todayAttendance = 0;
      if (activeEventId.isNotEmpty) {
        final attendanceSnap = await FirebaseFirestore.instance
            .collection("attendance")
            .where("eventId", isEqualTo: activeEventId)
            .where("seasonId", isEqualTo: seasonId)
            .get();
        todayAttendance = attendanceSnap.docs.length;
      }
      result["todayAttendance"] = todayAttendance;
      result["absentToday"] = totalUsers - todayAttendance >= 0
          ? totalUsers - todayAttendance
          : 0;

      // 4. Get all events of the selected season to compute attendance percentage dynamically
      final eventsSnap = await FirebaseFirestore.instance
          .collection("events")
          .where("seasonId", isEqualTo: seasonId)
          .get();
      final totalEventsCount = eventsSnap.docs.length;

      // Get all attendance logs for this season
      final attendanceSnap = await FirebaseFirestore.instance
          .collection("attendance")
          .where("seasonId", isEqualTo: seasonId)
          .get();

      // Group attendance by userId
      final Map<String, int> userAttendanceCounts = {};
      for (var doc in attendanceSnap.docs) {
        final uid = doc["userId"] as String;
        userAttendanceCounts[uid] = (userAttendanceCounts[uid] ?? 0) + 1;
      }

      // Calculate percentage for each user dynamically
      List<UserData> usersList = [];
      double totalPercentage = 0.0;
      for (var doc in usersSnap.docs) {
        final uid = doc.id;
        final data = doc.data() as Map<String, dynamic>;

        final userAttendance = userAttendanceCounts[uid] ?? 0;
        final percentage = totalEventsCount > 0
            ? (userAttendance / totalEventsCount) * 100.0
            : 0.0;

        final updatedData = Map<String, dynamic>.from(data);
        updatedData["attendancePercentage"] = double.parse(
          percentage.toStringAsFixed(1),
        );
        updatedData["totalAttendance"] = userAttendance;
        updatedData["totalAbsence"] = totalEventsCount - userAttendance >= 0
            ? totalEventsCount - userAttendance
            : 0;

        final u = UserData.fromJson(updatedData, uid);
        usersList.add(u);
        totalPercentage += u.attendancePercentage ?? 0.0;
      }

      result["totalUsers"] = totalUsers;
      result["avgAttendance"] = totalUsers > 0
          ? totalPercentage / totalUsers
          : 0.0;

      // 5. Rank Lists
      final topSorted = List<UserData>.from(usersList)
        ..sort(
          (a, b) => (b.attendancePercentage ?? 0.0).compareTo(
            a.attendancePercentage ?? 0.0,
          ),
        );
      final lowestSorted = usersList
          .where(
            (u) => AdminFollowUpHelper.isNeedingFollowUp(
              u.attendancePercentage ?? 0.0,
            ),
          )
          .toList()
        ..sort(
          (a, b) => (a.attendancePercentage ?? 0.0).compareTo(
            b.attendancePercentage ?? 0.0,
          ),
        );
      result["topUsers"] = topSorted;
      result["lowestUsers"] = lowestSorted;

      // 6. Graphs & Heatmap Data from attendance records in this season
      Map<int, int> weeklyData = {}; // dayOfWeek (1-7) -> count
      Map<int, int> monthlyData = {}; // month (1-12) -> count
      Map<String, int> heatmapData = {}; // YYYY-MM-DD -> count

      final now = DateTime.now();

      for (var doc in attendanceSnap.docs) {
        final timestamp = doc["timestamp"] as Timestamp?;
        if (timestamp != null) {
          final dt = timestamp.toDate();

          // Month grouping
          monthlyData[dt.month] = (monthlyData[dt.month] ?? 0) + 1;

          // Day of week grouping (only within last 30 days or general)
          if (now.difference(dt).inDays <= 7) {
            weeklyData[dt.weekday] = (weeklyData[dt.weekday] ?? 0) + 1;
          }

          // Heatmap grouping (exact date string)
          final dateKey =
              "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
          heatmapData[dateKey] = (heatmapData[dateKey] ?? 0) + 1;
        }
      }

      result["weeklyData"] = weeklyData;
      result["monthlyData"] = monthlyData;
      result["heatmapData"] = heatmapData;
    } catch (e) {
      debugPrint("Error calculating stats: $e");
    }

    return result;
  }
}
