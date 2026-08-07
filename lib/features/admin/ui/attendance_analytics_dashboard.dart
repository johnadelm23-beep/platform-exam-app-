import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';
import 'package:platformexamapp/core/services/offline_sync_service.dart';
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

  void _confirmResetAttendance(BuildContext context) {
    if (widget.user?.isAdmin != true) return;
    AppDialog.show(
      context: context,
      icon: Icons.warning_amber_rounded,
      iconColor: Colors.amber,
      title: "Reset Attendance",
      description:
          "This will permanently delete all attendance logs, streaks, and statistics. Student accounts will remain intact. This action cannot be undone. Are you sure?",
      confirmText: "Reset",
      confirmButtonColor: Colors.red,
      cancelText: "Cancel",
      onConfirm: () async {
        Navigator.pop(context); // Pop confirm dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(
            child: CircularProgressIndicator(color: Colors.white),
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
            setState(() {}); // Reload dashboard
          }
        } catch (e) {
          if (mounted) {
            Navigator.pop(context); // Pop loading
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Reset failed: $e"),
                backgroundColor: Colors.red,
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
    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        ),
        title: Text(
          "attendance_dashboard".tr(),
          style: TextStyle(color: Colors.white, fontWeight: .bold),
        ),
        centerTitle: true,
        actions: [
          if (widget.user?.isAdmin == true)
            IconButton(
              icon: const HugeIcon(icon: HugeIcons.strokeRoundedDelete01, color: Colors.white),
              tooltip: "Reset Attendance Data",
              onPressed: () => _confirmResetAttendance(context),
            ),
        ],
      ),
      body: Container(
        margin: EdgeInsets.only(top: 10.h),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30.r),
            topRight: Radius.circular(30.r),
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("seasons")
                    .orderBy("createdAt", descending: true)
                    .snapshots(),
                builder: (context, seasonSnapshot) {
                  final seasons = seasonSnapshot.data?.docs ?? [];
                  return DropdownButtonFormField<String>(
                    value: _selectedSeasonId,
                    decoration: InputDecoration(
                      labelText: "Selected Season",
                      fillColor: Colors.white,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15.r),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 10.h,
                      ),
                    ),
                    items: seasons.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final name = data["name"] ?? "Season";
                      final isActive = data["status"] == "active";
                      return DropdownMenuItem<String>(
                        value: doc.id,
                        child: Text(name + (isActive ? " (Active)" : "")),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedSeasonId = val;
                      });
                    },
                  );
                },
              ),
            ),
            Expanded(
              child: FutureBuilder<Map<String, dynamic>>(
                future: _calculateDashboardStats(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryColor,
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
                    padding: EdgeInsets.all(16.r),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Active Event Summary
                        _buildSectionHeader("current_active_event".tr()),
                        Card(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.r),
                          ),
                          elevation: 1,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primaryColor
                                  .withOpacity(0.1),
                              child: const HugeIcon(
                                icon: HugeIcons.strokeRoundedCalendar01,
                                color: AppColors.primaryColor,
                              ),
                            ),
                            title: Text(
                              activeEventTitle,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16.sp,
                              ),
                            ),
                            subtitle: Text("gate_for_scan".tr()),
                          ),
                        ),
                        SizedBox(height: 20.h),

                        // Stats Grid Cards
                        _buildSectionHeader("key_statistice".tr()),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1.6,
                          children: [
                            _buildStatCard(
                              "total_users".tr(),
                              "$totalUsers",
                              Colors.blue,
                              HugeIcons.strokeRoundedUser02,
                            ),
                            _buildStatCard(
                              "present_today".tr(),
                              "$todayAttendance",
                              Colors.green,
                              Icons.person_add,
                            ),
                            _buildStatCard(
                              "absent_today".tr(),
                              "$absentToday",
                              Colors.red,
                              Icons.person_remove,
                            ),
                            _buildStatCard(
                              "avg_atten".tr(),
                              "${avgAttendance.toStringAsFixed(1)}%",
                              Colors.purple,
                              HugeIcons.strokeRoundedActivity01,
                            ),
                          ],
                        ),
                        SizedBox(height: 25.h),

                        // Weekly Graph (Bar Chart)
                        _buildSectionHeader("weekly_atten_trend".tr()),
                        _buildWeeklyBarChart(weeklyData),
                        SizedBox(height: 25.h),

                        // Monthly Graph (Line Chart)
                        _buildSectionHeader("monthly_statistics".tr()),
                        _buildMonthlyLineChart(monthlyData),
                        SizedBox(height: 25.h),

                        // Density Heatmap
                        _buildSectionHeader("attent_heatmap".tr()),
                        _buildHeatmapGrid(heatmapData),
                        SizedBox(height: 25.h),

                        // Top Users List (All Members)
                        _buildSectionHeader("All Members Attendance Ranking"),

                        _buildUsersListView(topUsers),
                        SizedBox(height: 25.h),

                        // Lowest Attendance List
                        _buildSectionHeader("needs_attention".tr()),
                        _buildUsersListView(lowestUsers, isLowest: true),
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.bold,
          color: Colors.grey[800],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String val, Color color, dynamic icon) {
    return Card(
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
      child: Padding(
        padding: EdgeInsets.all(12.r),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: icon is IconData
                  ? Icon(icon as IconData, color: color, size: 24.r)
                  : icon is List<List<dynamic>>
                      ? HugeIcon(icon: icon as List<List<dynamic>>, color: color, size: 24.r)
                      : Icon(Icons.star, color: color, size: 24.r),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                    maxLines: 1,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    val,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyBarChart(Map<int, int> data) {
    final days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    List<BarChartGroupData> barGroups = [];

    for (int i = 1; i <= 7; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: (data[i] ?? 0).toDouble(),
              color: Colors.blue,
              width: 16.r,
              borderRadius: BorderRadius.circular(4.r),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 180.h,
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
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
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.grey[600],
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
    );
  }

  Widget _buildMonthlyLineChart(Map<int, int> data) {
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

    return Container(
      height: 180.h,
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
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
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.grey[600],
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
              color: Colors.purple,
              barWidth: 3.r,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.purple.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeatmapGrid(Map<String, int> heatmap) {
    // Generate dates for the last 28 days
    final now = DateTime.now();
    List<Widget> gridItems = [];

    for (int i = 27; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey =
          "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      final count = heatmap[dateKey] ?? 0;

      Color cellColor = Colors.grey[100]!;
      if (count > 0 && count <= 2) {
        cellColor = AppColors.primaryColor.withOpacity(0.3);
      } else if (count > 2 && count <= 5) {
        cellColor = AppColors.primaryColor.withOpacity(0.6);
      } else if (count > 5) {
        cellColor = AppColors.primaryColor;
      }

      gridItems.add(
        Tooltip(
          message: "$dateKey: $count attending",
          child: Container(
            decoration: BoxDecoration(
              color: cellColor,
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: Center(
              child: Text(
                "${date.day}",
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                  color: count > 2 ? Colors.white : Colors.black54,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: GridView.count(
        crossAxisCount: 7,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: 1.2,
        children: gridItems,
      ),
    );
  }

  Widget _buildUsersListView(List<UserData> users, {bool isLowest = false}) {
    if (users.isEmpty) {
      return Container(
        padding: EdgeInsets.all(12.r),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: const Text(
          "No user statistics compiled yet.",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: users.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final user = users[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: isLowest ? Colors.red[50] : Colors.green[50],
              child: Text(
                "${index + 1}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isLowest ? Colors.red : Colors.green,
                ),
              ),
            ),
            title: Text(
              user.name ?? "User",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(user.humanReadableId ?? ""),
            trailing: Text(
              "${user.attendancePercentage ?? 0.0}%",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isLowest ? Colors.red : Colors.green,
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
      final lowestSorted = List<UserData>.from(usersList)
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
