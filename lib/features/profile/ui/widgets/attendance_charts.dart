import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';

class AttendanceCharts extends StatefulWidget {
  final double attendancePct;
  final double absencePct;
  final Map<int, int> monthlyData; // Month 1..12 -> count
  final Map<int, int> weeklyData;  // Week day 1..7 -> count

  const AttendanceCharts({
    super.key,
    required this.attendancePct,
    required this.absencePct,
    this.monthlyData = const {},
    this.weeklyData = const {},
  });

  @override
  State<AttendanceCharts> createState() => _AttendanceChartsState();
}

class _AttendanceChartsState extends State<AttendanceCharts> {
  int touchedPieIndex = -1;
  int _selectedChartTab = 0; // 0: Pie Chart, 1: Bar Chart

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with switch between Pie Chart & Bar Chart
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "attendance_analytics".tr(),
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding: EdgeInsets.all(2.r),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  children: [
                    _buildTabButton(0, "Pie Chart"),
                    _buildTabButton(1, "Bar Chart"),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 20.h),

          // Chart Display
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _selectedChartTab == 0
                ? _buildPieChartSection()
                : _buildBarChartSection(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String label) {
    final isSelected = _selectedChartTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedChartTab = index),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  // ================= PIE CHART =================
  Widget _buildPieChartSection() {
    final attPct = widget.attendancePct.clamp(0.0, 100.0);
    final absPct = (100.0 - attPct).clamp(0.0, 100.0);

    return Column(
      key: const ValueKey("pie_chart_view"),
      children: [
        SizedBox(
          height: 180.h,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      touchedPieIndex = -1;
                      return;
                    }
                    touchedPieIndex =
                        pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 4,
              centerSpaceRadius: 40.r,
              sections: [
                PieChartSectionData(
                  color: AppColors.primaryColor,
                  value: attPct > 0 ? attPct : 1,
                  title: "${attPct.toStringAsFixed(0)}%",
                  radius: touchedPieIndex == 0 ? 55.r : 48.r,
                  titleStyle: TextStyle(
                    fontSize: touchedPieIndex == 0 ? 16.sp : 13.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                PieChartSectionData(
                  color: Colors.redAccent.shade100,
                  value: absPct > 0 ? absPct : 1,
                  title: "${absPct.toStringAsFixed(0)}%",
                  radius: touchedPieIndex == 1 ? 55.r : 48.r,
                  titleStyle: TextStyle(
                    fontSize: touchedPieIndex == 1 ? 16.sp : 13.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          ),
        ),
        SizedBox(height: 16.h),

        // Pie Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem("Attended".tr(), AppColors.primaryColor),
            SizedBox(width: 24.w),
            _buildLegendItem("Absent".tr(), Colors.redAccent.shade100),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 12.r,
          height: 12.r,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 6.w),
        Text(
          title,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  // ================= BAR CHART =================
  Widget _buildBarChartSection() {
    // Default fallback months data if empty
    final map = widget.monthlyData.isNotEmpty
        ? widget.monthlyData
        : {1: 4, 2: 6, 3: 5, 4: 8, 5: 7, 6: 9, 7: 6, 8: 8};

    final maxVal = map.values.isEmpty
        ? 10.0
        : (map.values.reduce((a, b) => a > b ? a : b) + 2).toDouble();

    return Column(
      key: const ValueKey("bar_chart_view"),
      children: [
        SizedBox(
          height: 180.h,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxVal,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => AppColors.primaryColor,
                  tooltipRoundedRadius: 8.r,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      "${rod.toY.toInt()} attended",
                      TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.sp,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      final monthNames = [
                        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
                      ];
                      final index = value.toInt() - 1;
                      if (index >= 0 && index < monthNames.length) {
                        return Padding(
                          padding: EdgeInsets.only(top: 6.h),
                          child: Text(
                            monthNames[index],
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                    reservedSize: 24,
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
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey[200]!,
                    strokeWidth: 1,
                  );
                },
              ),
              borderData: FlBorderData(show: false),
              barGroups: map.entries.map((entry) {
                return BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: entry.value.toDouble(),
                      color: AppColors.primaryColor,
                      width: 14.w,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(6.r),
                        topRight: Radius.circular(6.r),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          ),
        ),
      ],
    );
  }
}
