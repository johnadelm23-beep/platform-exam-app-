import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:platformexamapp/features/auth/data/models/user_data.dart';
import 'package:platformexamapp/features/profile/ui/widgets/user_avatar.dart';

class FollowUpUserCard extends StatelessWidget {
  final UserData user;
  final VoidCallback onEdit;
  final VoidCallback onDetails;
  final VoidCallback? onCallRecorded;

  const FollowUpUserCard({
    super.key,
    required this.user,
    required this.onEdit,
    required this.onDetails,
    this.onCallRecorded,
  });

  Future<void> _makeCall(BuildContext context) async {
    final phone = user.phone ?? user.email ?? '';
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("phone_number".tr()),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final Uri uri = Uri.parse("tel:$phone");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      onCallRecorded?.call();
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("couldnt_open".tr(args: [phone])),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case "Excellent":
      case "ممتاز":
        return const Color(0xFF2E7D32);
      case "Regular":
      case "منتظم":
        return const Color(0xFF1976D2);
      case "Needs Follow-up":
      case "بحاجة لافتقاد":
        return const Color(0xFFED6C02);
      case "Urgent":
      case "حالة عاجلة":
        return const Color(0xFFD32F2F);
      default:
        return const Color(0xFF0288D1);
    }
  }

  String _getLocalizedStatus(String status) {
    switch (status) {
      case "Excellent":
        return "status_excellent".tr();
      case "Needs Follow-up":
        return "status_needs_follow_up".tr();
      case "Urgent":
        return "status_urgent".tr();
      case "Regular":
      default:
        return "status_regular".tr();
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "not_set".tr();
    return DateFormat("yyyy/MM/dd").format(date);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusKey = user.followUpStatus ?? "Regular";
    final localizedStatus = _getLocalizedStatus(statusKey);
    final statusColor = _getStatusColor(statusKey);
    final attPct = user.attendancePercentage ?? 0.0;
    final lastCallStr = user.lastCallDate != null
        ? _formatDate(user.lastCallDate)
        : null;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: user.needVisit == true
              ? Colors.red.withValues(alpha: 0.6)
              : (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0)),
          width: user.needVisit == true ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Avatar + Name & Last Call + Status Badge
          Row(
            children: [
              UserAvatar(imageUrl: user.profileImage, radius: 24.r),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name ?? "",
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1F2937),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 3.h),
                    Row(
                      children: [
                        Text(
                          "${attPct.toStringAsFixed(0)}%",
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                            color: attPct >= 75
                                ? const Color(0xFF2E7D32)
                                : (attPct >= 50
                                      ? const Color(0xFFED6C02)
                                      : const Color(0xFFD32F2F)),
                          ),
                        ),
                        if (lastCallStr != null) ...[
                          SizedBox(width: 8.w),
                          Text(
                            "•  ${"last_call".tr()}: $lastCallStr",
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              // Follow-up Status Badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  localizedStatus,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Divider(
            height: 1,
            color: isDark ? Colors.grey[800] : const Color(0xFFEEEEEE),
          ),
          SizedBox(height: 8.h),

          // Buttons Row: 📞 Call, ✏ Edit, 👁 Details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildActionButton(
                context,
                icon: HugeIcons.strokeRoundedCall,
                label: "call".tr(),
                color: const Color(0xFF2E7D32),
                onPressed: () => _makeCall(context),
                isDark: isDark,
              ),
              _buildActionButton(
                context,
                icon: HugeIcons.strokeRoundedEdit02,
                label: "edit".tr(),
                color: const Color(0xFF1976D2),
                onPressed: onEdit,
                isDark: isDark,
              ),
              _buildActionButton(
                context,
                icon: HugeIcons.strokeRoundedView,
                label: "view_details".tr(),
                color: const Color(0xFF7B1FA2),
                onPressed: onDetails,
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required List<List<dynamic>> icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(10.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(icon: icon, color: color, size: 16.r),
            SizedBox(width: 6.w),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
