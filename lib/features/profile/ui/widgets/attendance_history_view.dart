import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';
import 'package:platformexamapp/core/widgets/empty_state.dart';
import 'package:platformexamapp/core/widgets/glass_card.dart';
import 'package:platformexamapp/core/widgets/loading_state.dart';

class AttendanceHistoryView extends StatelessWidget {
  final String uid;

  const AttendanceHistoryView({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextMain : AppColors.lightTextMain;
    final mutedColor = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("events")
          .orderBy("date", descending: true)
          .snapshots(),
      builder: (context, eventsSnapshot) {
        if (eventsSnapshot.connectionState == ConnectionState.waiting) {
          return const LoadingState();
        }

        final events = eventsSnapshot.data?.docs ?? [];
        if (events.isEmpty) {
          return EmptyState(
            title: "no_attendance_yet".tr(),
            hugeIcon: HugeIcons.strokeRoundedCalendar01,
          );
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("attendance")
              .where("userId", isEqualTo: uid)
              .snapshots(),
          builder: (context, attendanceSnapshot) {
            if (attendanceSnapshot.connectionState == ConnectionState.waiting) {
              return const LoadingState();
            }

            final attendanceDocs = attendanceSnapshot.data?.docs ?? [];
            final Set<String> attendedEventIds = attendanceDocs
                .map(
                  (doc) =>
                      (doc.data() as Map<String, dynamic>)["eventId"] as String,
                )
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
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStreakMetricsCard(
                          context,
                          attendedFridays,
                          totalFridays,
                          attendedSundays,
                          totalSundays,
                        ),
                        SizedBox(height: 20.h),
                        Text(
                          "attendance_statistics".tr(),
                          style: GoogleFonts.cairo(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        SizedBox(height: 10.h),
                        _buildMonthlyBarChart(context, monthlyAttendance),
                        SizedBox(height: 20.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "meeting_history".tr(),
                              style: GoogleFonts.cairo(
                                fontSize: 17.sp,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.softGold.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Text(
                                "${historyList.length}",
                                style: GoogleFonts.cairo(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.softGold,
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
                      child: EmptyState(
                        title: "no_attendance_yet".tr(),
                        hugeIcon: HugeIcons.strokeRoundedCalendar01,
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
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final item = historyList[index];
                        final isPresent = item["isPresent"] as bool;
                        final type = item["type"] as String;

                        return Padding(
                          padding: EdgeInsets.only(bottom: 10.h),
                          child: _buildHistoryCard(
                            context,
                            title: item["title"],
                            date: item["date"],
                            type: type,
                            isPresent: isPresent,
                          ),
                        );
                      }, childCount: historyList.length),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildHistoryCard(
    BuildContext context, {
    required String title,
    required String date,
    required String type,
    required bool isPresent,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextMain : AppColors.lightTextMain;
    final mutedColor = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;

    List<List<dynamic>> typeIcon;
    String typeLabel;
    Color typeColor;

    if (type == 'friday_meeting') {
      typeIcon = HugeIcons.strokeRoundedCalendar01;
      typeLabel = 'friday'.tr();
      typeColor = AppColors.softGold;
    } else if (type == 'sunday_activity') {
      typeIcon = HugeIcons.strokeRoundedClock01;
      typeLabel = 'sunday'.tr();
      typeColor = Colors.orange.shade400;
    } else {
      typeIcon = HugeIcons.strokeRoundedTicket01;
      typeLabel = 'custom'.tr();
      typeColor = Colors.purple.shade300;
    }

    return GlassCard(
      padding: EdgeInsets.all(14.r),
      borderRadius: 18.r,
      child: Row(
        children: [
          // Type Icon Avatar
          Container(
            width: 44.r,
            height: 44.r,
            decoration: BoxDecoration(
              color: isPresent
                  ? AppColors.successGreen.withOpacity(0.15)
                  : AppColors.heartRed.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: HugeIcon(
              icon: isPresent
                  ? HugeIcons.strokeRoundedCheckmarkBadge01
                  : HugeIcons.strokeRoundedCancelSquare,
              color: isPresent ? AppColors.successGreen : AppColors.heartRed,
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
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                    color: textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    HugeIcon(icon: typeIcon, size: 12.r, color: typeColor),
                    SizedBox(width: 4.w),
                    Text(
                      "$date • $typeLabel",
                      style: GoogleFonts.cairo(
                        fontSize: 12.sp,
                        color: mutedColor,
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
                  ? AppColors.successGreen.withOpacity(0.15)
                  : AppColors.heartRed.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: isPresent
                    ? AppColors.successGreen.withOpacity(0.3)
                    : AppColors.heartRed.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPresent ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  size: 13.r,
                  color: isPresent
                      ? AppColors.successGreen
                      : AppColors.heartRed,
                ),
                SizedBox(width: 4.w),
                Text(
                  isPresent ? "present".tr() : "absent".tr(),
                  style: GoogleFonts.cairo(
                    color: isPresent
                        ? AppColors.successGreen
                        : AppColors.heartRed,
                    fontWeight: FontWeight.bold,
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakMetricsCard(
    BuildContext context,
    int presentF,
    int totalF,
    int presentS,
    int totalS,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    double fridayPct = totalF > 0 ? (presentF / totalF) * 100 : 0.0;
    double sundayPct = totalS > 0 ? (presentS / totalS) * 100 : 0.0;

    return GlassCard(
      padding: EdgeInsets.all(16.r),
      borderRadius: 20.r,
      child: Row(
        children: [
          Expanded(
            child: _buildStatMetric(
              context,
              icon: HugeIcons.strokeRoundedCalendar01,
              label: "friday_attendance".tr(),
              value: "${fridayPct.toStringAsFixed(1)}%",
              subtext: "$presentF / $totalF",
            ),
          ),
          Container(height: 35.h, width: 1, color: borderColor),
          Expanded(
            child: _buildStatMetric(
              context,
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

  Widget _buildStatMetric(
    BuildContext context, {
    required List<List<dynamic>> icon,
    required String label,
    required String value,
    required String subtext,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextMain : AppColors.lightTextMain;
    final mutedColor = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HugeIcon(icon: icon, size: 14.r, color: AppColors.softGold),
            SizedBox(width: 4.w),
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 11.sp,
                color: mutedColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: GoogleFonts.cairo(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.softGold,
          ),
        ),
        Text(
          subtext,
          style: GoogleFonts.cairo(fontSize: 10.sp, color: mutedColor),
        ),
      ],
    );
  }

  Widget _buildMonthlyBarChart(BuildContext context, Map<int, int> data) {
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

    List<BarChartGroupData> barGroups = [];
    for (int i = 1; i <= 12; i++) {
      final val = (data[i] ?? 0).toDouble();
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: val,
              color: AppColors.softGold,
              width: 10.r,
              borderRadius: BorderRadius.circular(4.r),
            ),
          ],
        ),
      );
    }

    return GlassCard(
      padding: EdgeInsets.all(12.r),
      borderRadius: 20.r,
      child: SizedBox(
        height: 160.h,
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
                          style: GoogleFonts.cairo(
                            fontSize: 9.sp,
                            color: AppColors.softGold,
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
}
