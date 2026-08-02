import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';

class SegmentedTabBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabChanged;

  const SegmentedTabBar({
    super.key,
    required this.selectedIndex,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48.h,
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(4.r),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(24.r),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = (constraints.maxWidth) / 2;

          return Stack(
            children: [
              // Animated Sliding Pill Indicator
              AnimatedAlign(
                alignment: selectedIndex == 0
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOutCubic,
                child: Container(
                  width: tabWidth,
                  height: constraints.maxHeight,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),

              // Interactive Tab Items
              Row(
                children: [
                  Expanded(
                    child: _buildTabItem(
                      index: 0,
                      title: "attendance".tr(),
                      icon: HugeIcons.strokeRoundedCalendar01,
                      isSelected: selectedIndex == 0,
                    ),
                  ),
                  Expanded(
                    child: _buildTabItem(
                      index: 1,
                      title: "exams".tr(),
                      icon: HugeIcons.strokeRoundedFile01,
                      isSelected: selectedIndex == 1,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTabItem({
    required int index,
    required String title,
    required List<List<dynamic>> icon,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () => onTabChanged(index),
      borderRadius: BorderRadius.circular(20.r),
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Row(
            key: ValueKey<bool>(isSelected),
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              HugeIcon(
                icon: icon,
                size: 18.r,
                color: isSelected
                    ? AppColors.primaryColor
                    : Colors.white.withValues(alpha: 0.8),
              ),
              SizedBox(width: 8.w),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? AppColors.primaryColor
                      : Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
