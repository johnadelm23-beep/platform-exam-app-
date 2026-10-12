import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';

class AttendanceCharts extends StatefulWidget {
  final double attendancePct;
  final double absencePct;
  final Map<int, int> monthlyData; // Month 1..12 -> count
  final Map<int, int> weeklyData; // Week day 1..7 -> count

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.slate200;
    final textColor = isDark ? AppColors.darkTextMain : AppColors.classicNavy;
    final subtitleColor = isDark ? AppColors.darkTextMuted : AppColors.slate500;

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: AppColors.classicNavy.withValues(alpha: 0.04),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
        border: Border.all(color: borderColor),
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
                style: GoogleFonts.cairo(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              Container(
                padding: EdgeInsets.all(3.r),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : AppColors.slate100,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  children: [
                    _buildTabButton(0, "pie_chart".tr(), isDark),
                    _buildTabButton(1, "bar_chart".tr(), isDark),
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
                ? _buildPieChartSection(isDark, subtitleColor)
                : _buildBarChartSection(isDark, subtitleColor),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String label, bool isDark) {
    final isSelected = _selectedChartTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedChartTab = index),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentTeal
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 11.sp,
            fontWeight: FontWeight.bold,
            color: isSelected
                ? Colors.white
                : (isDark ? AppColors.darkTextCaption : AppColors.slate500),
          ),
        ),
      ),
    );
  }

  // ================= PIE CHART =================
  Widget _buildPieChartSection(bool isDark, Color subtitleColor) {
    final attPct = widget.attendancePct.clamp(0.0, 100.0);
    final absPct = widget.absencePct.clamp(0.0, 100.0);

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
                  color: AppColors.accentTeal,
                  value: attPct > 0 ? attPct : 1,
                  title: "${attPct.toStringAsFixed(0)}%",
                  radius: touchedPieIndex == 0 ? 55.r : 48.r,
                  titleStyle: GoogleFonts.cairo(
                    fontSize: touchedPieIndex == 0 ? 16.sp : 13.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                PieChartSectionData(
                  color: AppColors.heartRed.withValues(alpha: 0.8),
                  value: absPct > 0 ? absPct : 1,
                  title: "${absPct.toStringAsFixed(0)}%",
                  radius: touchedPieIndex == 1 ? 55.r : 48.r,
                  titleStyle: GoogleFonts.cairo(
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
            _buildLegendItem(
              "Attended".tr(),
              AppColors.accentTeal,
              subtitleColor,
            ),
            SizedBox(width: 24.w),
            _buildLegendItem(
              "Absent".tr(),
              AppColors.heartRed.withValues(alpha: 0.8),
              subtitleColor,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(String title, Color color, Color subtitleColor) {
    return Row(
      children: [
        Container(
          width: 12.r,
          height: 12.r,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 6.w),
        Text(
          title,
          style: GoogleFonts.cairo(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: subtitleColor,
          ),
        ),
      ],
    );
  }

  // ================= BAR CHART =================
  Widget _buildBarChartSection(bool isDark, Color subtitleColor) {
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
                  getTooltipColor: (_) => AppColors.classicNavy,
                  tooltipRoundedRadius: 8.r,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      "${rod.toY.toInt()} attended",
                      GoogleFonts.cairo(
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
                        'Jan',
                        'Feb',
                        'Mar',
                        'Apr',
                        'May',
                        'Jun',
                        'Jul',
                        'Aug',
                        'Sep',
                        'Oct',
                        'Nov',
                        'Dec',
                      ];
                      final index = value.toInt() - 1;
                      if (index >= 0 && index < monthNames.length) {
                        return Padding(
                          padding: EdgeInsets.only(top: 6.h),
                          child: Text(
                            monthNames[index],
                            style: GoogleFonts.cairo(
                              fontSize: 10.sp,
                              color: subtitleColor,
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
                    color: isDark ? AppColors.darkBorder : AppColors.slate200,
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
                      color: AppColors.accentTeal,
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
