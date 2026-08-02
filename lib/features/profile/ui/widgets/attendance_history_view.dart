import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconly/iconly.dart';
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
          return const Center(child: CircularProgressIndicator(color: AppColors.primaryColor));
        }

        final events = eventsSnapshot.data?.docs ?? [];
        if (events.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(IconlyLight.calendar, size: 50.r, color: Colors.grey[300]),
                SizedBox(height: 10.h),
                Text("no_attendance_yet".tr(), style: const TextStyle(color: Colors.grey)),
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
              return const Center(child: CircularProgressIndicator(color: AppColors.primaryColor));
            }

            final attendanceDocs = attendanceSnapshot.data?.docs ?? [];
            final Set<String> attendedEventIds = attendanceDocs
                .map((doc) => (doc.data() as Map<String, dynamic>)["eventId"] as String)
                .toSet();

            // Match events with attendance records
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

              // Check if event is in the past or today
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

            // Group attendance by month for charts (e.g. Jan=1, Feb=2...)
            Map<int, int> monthlyAttendance = {};
            for (var doc in attendanceDocs) {
              final data = doc.data() as Map<String, dynamic>;
              final timestamp = data["timestamp"] as Timestamp?;
              if (timestamp != null) {
                final month = timestamp.toDate().month;
                monthlyAttendance[month] = (monthlyAttendance[month] ?? 0) + 1;
              }
            }

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Streak Metrics Card
                  _buildStreakMetricsCard(attendedFridays, totalFridays, attendedSundays, totalSundays),
                  
                  SizedBox(height: 20.h),
                  
                  // Charts Section
                  Text(
                    "attendance_statistics".tr(),
                    style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10.h),
                  _buildMonthlyBarChart(monthlyAttendance),
                  
                  SizedBox(height: 25.h),

                  // History List
                  Text(
                    "meeting_history".tr(),
                    style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10.h),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: historyList.length,
                    separatorBuilder: (_, __) => SizedBox(height: 10.h),
                    itemBuilder: (context, index) {
                      final item = historyList[index];
                      final isPresent = item["isPresent"] as bool;
                      final type = item["type"] as String;

                      return Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isPresent
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            child: Icon(
                              isPresent ? Icons.check_circle : Icons.cancel,
                              color: isPresent ? Colors.green : Colors.red,
                            ),
                          ),
                          title: Text(
                            item["title"],
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
                          ),
                          subtitle: Text(
                            "${item["date"]} • ${type == 'friday_meeting' ? 'friday'.tr() : type == 'sunday_activity' ? 'sunday'.tr() : 'custom'.tr()}",
                            style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                          ),
                          trailing: Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: isPresent ? Colors.green[50] : Colors.red[50],
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              isPresent ? "present".tr() : "absent".tr(),
                              style: TextStyle(
                                color: isPresent ? Colors.green[700] : Colors.red[700],
                                fontWeight: FontWeight.bold,
                                fontSize: 12.sp,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStreakMetricsCard(int presentF, int totalF, int presentS, int totalS) {
    double fridayPct = totalF > 0 ? (presentF / totalF) * 100 : 0.0;
    double sundayPct = totalS > 0 ? (presentS / totalS) * 100 : 0.0;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatMetric("friday_attendance".tr(), "${fridayPct.toStringAsFixed(1)}% ($presentF/$totalF)"),
                _buildStatMetric("sunday_attendance".tr(), "${sundayPct.toStringAsFixed(1)}% ($presentS/$totalS)"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatMetric(String label, String value) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12.sp, color: Colors.grey[600])),
        SizedBox(height: 5.h),
        Text(value, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: AppColors.primaryColor)),
      ],
    );
  }

  Widget _buildMonthlyBarChart(Map<int, int> data) {
    final List<String> monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    
    // Fill monthly data
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
              width: 12.r,
              borderRadius: BorderRadius.circular(4.r),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 180.h,
      padding: EdgeInsets.all(10.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey[200]!),
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
