import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';

class FollowUpFiltersWidget extends StatefulWidget {
  final String searchQuery;
  final String attendanceFilter;
  final String needVisitFilter;
  final String statusFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onAttendanceFilterChanged;
  final ValueChanged<String> onNeedVisitFilterChanged;
  final ValueChanged<String> onStatusFilterChanged;

  const FollowUpFiltersWidget({
    super.key,
    required this.searchQuery,
    required this.attendanceFilter,
    required this.needVisitFilter,
    required this.statusFilter,
    required this.onSearchChanged,
    required this.onAttendanceFilterChanged,
    required this.onNeedVisitFilterChanged,
    required this.onStatusFilterChanged,
  });

  @override
  State<FollowUpFiltersWidget> createState() => _FollowUpFiltersWidgetState();
}

class _FollowUpFiltersWidgetState extends State<FollowUpFiltersWidget> {
  bool _isFilterExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasActiveFilters = widget.attendanceFilter != 'All' ||
        widget.needVisitFilter != 'All' ||
        widget.statusFilter != 'All';

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Search Bar & Filter Toggle Button
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: widget.onSearchChanged,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: "search_by_name_hint".tr(),
                    hintStyle: TextStyle(fontSize: 13.sp, color: isDark ? Colors.grey[400] : Colors.grey[500]),
                    prefixIcon: HugeIcon(
                      icon: HugeIcons.strokeRoundedSearch01,
                      color: isDark ? Colors.grey[400]! : Colors.grey[600]!,
                      size: 18.r,
                    ),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF3F4F6),
                    contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14.r),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              // Filter Button
              InkWell(
                onTap: () => setState(() => _isFilterExpanded = !_isFilterExpanded),
                borderRadius: BorderRadius.circular(14.r),
                child: Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: hasActiveFilters
                        ? Theme.of(context).primaryColor
                        : (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF3F4F6)),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Row(
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedFilter,
                        color: hasActiveFilters ? Colors.white : (isDark ? Colors.white : Colors.black87),
                        size: 18.r,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        "filter".tr(),
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                          color: hasActiveFilters ? Colors.white : (isDark ? Colors.white : Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Expandable Filter Controls
          if (_isFilterExpanded) ...[
            SizedBox(height: 12.h),
            Divider(height: 1, color: isDark ? Colors.grey[800] : const Color(0xFFEEEEEE)),
            SizedBox(height: 10.h),
            Row(
              children: [
                Expanded(
                  child: _buildFilterDropdown(
                    context,
                    label: "attendance".tr(),
                    value: widget.attendanceFilter,
                    items: [
                      DropdownMenuItem(value: "All", child: Text("all".tr())),
                      const DropdownMenuItem(value: "<50%", child: Text("< 50%")),
                      const DropdownMenuItem(value: "50-75%", child: Text("50% - 75%")),
                      const DropdownMenuItem(value: ">75%", child: Text("> 75%")),
                    ],
                    onChanged: widget.onAttendanceFilterChanged,
                    isDark: isDark,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: _buildFilterDropdown(
                    context,
                    label: "need_visit".tr(),
                    value: widget.needVisitFilter,
                    items: [
                      DropdownMenuItem(value: "All", child: Text("all".tr())),
                      DropdownMenuItem(value: "Yes", child: Text("yes".tr())),
                      DropdownMenuItem(value: "No", child: Text("no".tr())),
                    ],
                    onChanged: widget.onNeedVisitFilterChanged,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            _buildFilterDropdown(
              context,
              label: "follow_up_status".tr(),
              value: widget.statusFilter,
              items: [
                DropdownMenuItem(value: "All", child: Text("all".tr())),
                DropdownMenuItem(value: "Excellent", child: Text("status_excellent".tr())),
                DropdownMenuItem(value: "Regular", child: Text("status_regular".tr())),
                DropdownMenuItem(value: "Needs Follow-up", child: Text("status_needs_follow_up".tr())),
                DropdownMenuItem(value: "Urgent", child: Text("status_urgent".tr())),
              ],
              onChanged: widget.onStatusFilterChanged,
              isDark: isDark,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(
    BuildContext context, {
    required String label,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String> onChanged,
    required bool isDark,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : const Color(0xFFE5E7EB),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18.r,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
          dropdownColor: isDark ? const Color(0xFF2E2E2E) : Colors.white,
          onChanged: (val) {
            if (val != null) onChanged(val);
          },
          items: items,
        ),
      ),
    );
  }
}
