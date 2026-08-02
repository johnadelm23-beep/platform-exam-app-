import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';

class AttendanceHistoryView extends StatelessWidget {
  final String uid;

  const AttendanceHistoryView({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("events")
          .orderBy("date", descending: true)
          .snapshots(),
      builder: (context, eventsSnapshot) {
        if (eventsSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryColor),
          );
        }

        final events = eventsSnapshot.data?.docs ?? [];
        if (events.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedCalendar01,
                  size: 50.r,
                  color: Colors.grey[300],
                ),
                SizedBox(height: 10.h),
                Text(
                  "no_attendance_yet".tr(),
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("attendance")
              .where("userId", isEqualTo: uid)
              .snapshots(),
          builder: (context, attendanceSnapshot) {
            if (attendanceSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primaryColor),
              );
            }

            final attendanceDocs = attendanceSnapshot.data?.docs ?? [];
            final Set<String> attendedEventIds = attendanceDocs
                .map((doc) => (doc.data() as Map<String, dynamic>)["eventId"] as String)
                .toSet();

            List<Map<String, dynamic>> historyList = [];
            int totalFridays = 0;
            int attendedFridays = 0;
            int totalSundays = 0;
            int attendedSundays = 0;

            final nowStr = DateTime.now().toIso8601String().substring(0, 10);

            for (var eventDoc in events) {
              final data = eventDoc.data() as Map<String, dynamic>;
              final eventId = eventDoc.id;
              final eventDate = data["date"] ?? "";
              final type = data["type"] ?? "";
              final title = data["title"] ?? "Event";

              if (eventDate.compareTo(nowStr) <= 0) {
                final isPresent = attendedEventIds.contains(eventId);

                if (type == "friday_meeting") {
                  totalFridays++;
                  if (isPresent) attendedFridays++;
                } else if (type == "sunday_activity") {
                  totalSundays++;
                  if (isPresent) attendedSundays++;
                }

                historyList.add({
                  "title": title,
                  "date": eventDate,
                  "type": type,
                  "isPresent": isPresent,
                });
              }
            }

            // Monthly attendance mapping for chart
            Map<int, int> monthlyAttendance = {};
            for (var doc in attendanceDocs) {
              final data = doc.data() as Map<String, dynamic>;
              final timestamp = data["timestamp"] as Timestamp?;
              if (timestamp != null) {
                final month = timestamp.toDate().month;
                monthlyAttendance[month] = (monthlyAttendance[month] ?? 0) + 1;
              }
            }

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStreakMetricsCard(
                          attendedFridays,
                          totalFridays,
                          attendedSundays,
                          totalSundays,
                        ),
                        SizedBox(height: 20.h),
                        Text(
                          "attendance_statistics".tr(),
                          style: TextStyle(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 10.h),
                        _buildMonthlyBarChart(monthlyAttendance),
                        SizedBox(height: 20.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "meeting_history".tr(),
                              style: TextStyle(
                                fontSize: 17.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Text(
                                "${historyList.length}",
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10.h),
                      ],
                    ),
                  ),
                ),

                // Lazy-loaded History Cards List
                if (historyList.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(30.r),
                      child: Center(
                        child: Text(
                          "no_attendance_yet".tr(),
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.only(
                      left: 16.w,
                      right: 16.w,
                      bottom: 24.h,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = historyList[index];
                          final isPresent = item["isPresent"] as bool;
                          final type = item["type"] as String;

                          return Padding(
                            padding: EdgeInsets.only(bottom: 10.h),
                            child: _buildHistoryCard(
                              title: item["title"],
                              date: item["date"],
                              type: type,
                              isPresent: isPresent,
                            ),
                          );
                        },
                        childCount: historyList.length,
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildHistoryCard({
    required String title,
    required String date,
    required String type,
    required bool isPresent,
  }) {
    List<List<dynamic>> typeIcon;
    String typeLabel;
    Color typeColor;

    if (type == 'friday_meeting') {
      typeIcon = HugeIcons.strokeRoundedCalendar01;
      typeLabel = 'friday'.tr();
      typeColor = AppColors.primaryColor;
    } else if (type == 'sunday_activity') {
      typeIcon = HugeIcons.strokeRoundedClock01;
      typeLabel = 'sunday'.tr();
      typeColor = Colors.orange;
    } else {
      typeIcon = HugeIcons.strokeRoundedTicket01;
      typeLabel = 'custom'.tr();
      typeColor = Colors.purple;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.15),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(14.r),
              child: Row(
                children: [
                  // Type Icon Avatar
                  Container(
                    width: 44.r,
                    height: 44.r,
                    decoration: BoxDecoration(
                      color: isPresent
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: HugeIcon(
                      icon: isPresent ? HugeIcons.strokeRoundedCheckmarkBadge01 : HugeIcons.strokeRoundedCancelSquare,
                      color: isPresent ? Colors.green[600] : Colors.red[500],
                      size: 22.r,
                    ),
                  ),
                  SizedBox(width: 12.w),

                  // Title & Meta Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14.sp,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4.h),
                        Row(
                          children: [
                            HugeIcon(
                              icon: typeIcon,
                              size: 12.r,
                              color: typeColor,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              "$date • $typeLabel",
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(width: 8.w),

                  // Attendance Status Pill
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                    decoration: BoxDecoration(
                      color: isPresent
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: isPresent
                            ? Colors.green.withValues(alpha: 0.3)
                            : Colors.red.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPresent ? Icons.check_circle_rounded : Icons.cancel_rounded,
                          size: 13.r,
                          color: isPresent ? Colors.green[700] : Colors.red[700],
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          isPresent ? "present".tr() : "absent".tr(),
                          style: TextStyle(
                            color: isPresent ? Colors.green[800] : Colors.red[800],
                            fontWeight: FontWeight.bold,
                            fontSize: 11.sp,
                          ),
                        ),
                      ],
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

  Widget _buildStreakMetricsCard(
    int presentF,
    int totalF,
    int presentS,
    int totalS,
  ) {
    double fridayPct = totalF > 0 ? (presentF / totalF) * 100 : 0.0;
    double sundayPct = totalS > 0 ? (presentS / totalS) * 100 : 0.0;

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatMetric(
              icon: HugeIcons.strokeRoundedCalendar01,
              label: "friday_attendance".tr(),
              value: "${fridayPct.toStringAsFixed(1)}%",
              subtext: "$presentF / $totalF",
            ),
          ),
          Container(
            height: 35.h,
            width: 1,
            color: Colors.grey[200],
          ),
          Expanded(
            child: _buildStatMetric(
              icon: HugeIcons.strokeRoundedClock01,
              label: "sunday_attendance".tr(),
              value: "${sundayPct.toStringAsFixed(1)}%",
              subtext: "$presentS / $totalS",
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatMetric({
    required List<List<dynamic>> icon,
    required String label,
    required String value,
    required String subtext,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HugeIcon(icon: icon, size: 14.r, color: AppColors.primaryColor),
            SizedBox(width: 4.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor,
          ),
        ),
        Text(
          subtext,
          style: TextStyle(fontSize: 10.sp, color: Colors.grey[500]),
        ),
      ],
    );
  }

  Widget _buildMonthlyBarChart(Map<int, int> data) {
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
      "Dec"
    ];

    List<BarChartGroupData> barGroups = [];
    for (int i = 1; i <= 12; i++) {
      final val = (data[i] ?? 0).toDouble();
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: val,
              color: AppColors.primaryColor,
              width: 10.r,
              borderRadius: BorderRadius.circular(4.r),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 170.h,
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 10,
          barTouchData: BarTouchData(enabled: true),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  int monthIndex = value.toInt() - 1;
                  if (monthIndex >= 0 && monthIndex < 12) {
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text(
                        monthNames[monthIndex],
                        style: TextStyle(fontSize: 9.sp, color: Colors.grey[600]),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: barGroups,
        ),
      ),
    );
  }
}
