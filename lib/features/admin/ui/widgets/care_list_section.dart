import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';
import 'package:platformexamapp/features/admin/utils/admin_follow_up_helper.dart';
import 'package:platformexamapp/features/auth/data/models/user_data.dart';
import 'package:platformexamapp/features/profile/ui/widgets/user_avatar.dart';

class CareListSection extends StatelessWidget {
  const CareListSection({super.key});

  Future<void> _makeCall(String? phone) async {
    final phoneNumber = phone ?? "";
    if (phoneNumber.isEmpty) return;
    final Uri uri = Uri.parse("tel:$phoneNumber");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _sendWhatsApp(String? phone, String name) async {
    final phoneNumber = phone ?? "";
    final message =
        "Hello $name, we missed you at Egtma3na! Is everything okay?";
    final Uri uri = Uri.parse(
      "https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}",
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(6.r),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedAlert02,
                    color: Colors.red,
                    size: 18.r,
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  "members_needing_followup".tr(),
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 12.h),

        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection("users").snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primaryColor),
              );
            }

            final docs = snapshot.data?.docs ?? [];
            List<UserData> needyMembers = [];

            for (var doc in docs) {
              final user = UserData.fromJson(
                doc.data() as Map<String, dynamic>,
                doc.id,
              );

              final pct = user.attendancePercentage ?? 0.0;

              // Filter rule: Attendance <= 70%
              if (AdminFollowUpHelper.isNeedingFollowUp(pct)) {
                needyMembers.add(user);
              }
            }

            if (needyMembers.isEmpty) {
              return Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green[600]),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        "all_members_healthy".tr(),
                        style: TextStyle(
                          color: Colors.green[800],
                          fontWeight: FontWeight.bold,
                          fontSize: 13.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: needyMembers.length,
              separatorBuilder: (_, __) => SizedBox(height: 10.h),
              itemBuilder: (context, index) {
                final member = needyMembers[index];
                final pct = member.attendancePercentage ?? 0.0;
                final lastDateStr = member.lastAttendanceDate != null
                    ? "${member.lastAttendanceDate!.year}-${member.lastAttendanceDate!.month.toString().padLeft(2, '0')}-${member.lastAttendanceDate!.day.toString().padLeft(2, '0')}"
                    : "No records";

                return Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      UserAvatar(
                        imageUrl: member.profileImage,
                        radius: 24.r,
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              member.name ?? "Member",
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 2.h),
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6.w,
                                    vertical: 2.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6.r),
                                  ),
                                  child: Text(
                                    "${pct.toStringAsFixed(0)}% Att.",
                                    style: TextStyle(
                                      fontSize: 10.sp,
                                      color: Colors.red[700],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 6.w),
                                Text(
                                  "Last: $lastDateStr",
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 8.w),

                      // WhatsApp Quick Action
                      IconButton(
                        onPressed: () => _sendWhatsApp(
                          member.email,
                          member.name ?? "Member",
                        ),
                        icon: const HugeIcon(
                          icon: HugeIcons.strokeRoundedComment01,
                          color: Color(0xFF25D366),
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(
                            0xFF25D366,
                          ).withValues(alpha: 0.1),
                        ),
                        tooltip: "WhatsApp",
                      ),

                      // Call Quick Action
                      IconButton(
                        onPressed: () => _makeCall(member.email),
                        icon: const HugeIcon(
                          icon: HugeIcons.strokeRoundedCall,
                          color: Colors.blue,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.blue.withValues(alpha: 0.1),
                        ),
                        tooltip: "Call",
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
