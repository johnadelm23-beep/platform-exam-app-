import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';
import 'package:platformexamapp/core/widgets/app_dialog.dart';
import 'package:platformexamapp/core/widgets/empty_state.dart';
import 'package:platformexamapp/core/widgets/glass_card.dart';
import 'package:platformexamapp/features/auth/data/models/user_data.dart';

class DailyContentHistoryScreen extends StatefulWidget {
  const DailyContentHistoryScreen({super.key, this.user});
  final UserData? user;

  @override
  State<DailyContentHistoryScreen> createState() =>
      _DailyContentHistoryScreenState();
}

class _DailyContentHistoryScreenState extends State<DailyContentHistoryScreen> {
  Future<int> _getAttendanceCount(String eventId) async {
    if (eventId.isEmpty) return 0;
    try {
      final snap = await FirebaseFirestore.instance
          .collection("attendance")
          .where("eventId", isEqualTo: eventId)
          .get();
      return snap.docs.length;
    } catch (_) {
      return 0;
    }
  }

  void _clearArchivedContents() {
    if (widget.user?.isAdmin != true) return;
    AppDialog.show(
      context: context,
      icon: Icons.delete_forever,
      iconColor: AppColors.heartRed,
      title: "Clear Content History",
      description:
          "This will permanently delete all archived daily content. Active content will never be deleted. This action cannot be undone. Do you wish to proceed?",
      confirmText: "Clear History",
      confirmButtonColor: AppColors.heartRed,
      cancelText: "Cancel",
      onConfirm: () async {
        Navigator.pop(context); // Close dialog
        try {
          final query = await FirebaseFirestore.instance
              .collection("daily_content")
              .where("isArchived", isEqualTo: true)
              .get();

          final batch = FirebaseFirestore.instance.batch();
          int count = 0;
          for (var doc in query.docs) {
            final data = doc.data();
            // Never delete active content
            if (data["isActive"] != true) {
              batch.delete(doc.reference);
              count++;
            }
          }
          await batch.commit();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Cleared $count archived content logs."),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Error clearing history: $e"),
                backgroundColor: AppColors.heartRed,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageBg = isDark ? AppColors.darkPageBg : AppColors.lightPageBg;
    final surfaceColor = isDark
        ? AppColors.darkSurface
        : AppColors.lightSurface;
    final textColor = isDark ? AppColors.darkTextMain : AppColors.lightTextMain;
    final mutedColor = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: pageBg,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: textColor,
            size: 20.r,
          ),
        ),
        title: Text(
          "Daily Content History",
          style: GoogleFonts.cairo(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
        ),
        centerTitle: true,
        actions: [
          if (widget.user?.isAdmin == true)
            IconButton(
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedDelete01,
                color: AppColors.heartRed,
                size: 20.r,
              ),
              tooltip: "Clear Archived",
              onPressed: _clearArchivedContents,
            ),
        ],
      ),
      body: Container(
        margin: EdgeInsets.only(top: 10.h),
        padding: EdgeInsets.all(16.r),
        width: double.infinity,
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32.r),
            topRight: Radius.circular(32.r),
          ),
          border: Border(top: BorderSide(color: borderColor, width: 1)),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("daily_content")
              .orderBy("createdDate", descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.softGold),
              );
            }

            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return EmptyState(
                title: "No content items found.",
                hugeIcon: HugeIcons.strokeRoundedFileBookmark,
              );
            }

            return ListView.separated(
              physics: const BouncingScrollPhysics(),
              itemCount: docs.length,
              separatorBuilder: (_, __) => SizedBox(height: 12.h),
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data() as Map<String, dynamic>;
                final title = data["title"] ?? "Untitled";
                final eventId = data["eventId"] ?? "";
                final createdBy = data["createdBy"] ?? "Admin";
                final isActive = data["isActive"] ?? false;
                final isArchived = data["isArchived"] ?? false;

                final createdDateStamp = data["createdDate"] as Timestamp?;
                final createdDateStr = createdDateStamp != null
                    ? createdDateStamp.toDate().toIso8601String().substring(
                        0,
                        10,
                      )
                    : "N/A";

                return FutureBuilder<int>(
                  future: _getAttendanceCount(eventId),
                  builder: (context, countSnap) {
                    final attendanceCount = countSnap.data ?? 0;

                    final badgeColor = isActive
                        ? Colors.green
                        : isArchived
                        ? AppColors.softGold
                        : Colors.blue;

                    return GlassCard(
                      padding: EdgeInsets.all(14.r),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                createdDateStr,
                                style: GoogleFonts.cairo(
                                  fontSize: 12.sp,
                                  color: mutedColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10.w,
                                  vertical: 4.h,
                                ),
                                decoration: BoxDecoration(
                                  color: badgeColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12.r),
                                  border: Border.all(
                                    color: badgeColor.withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Text(
                                  isActive
                                      ? "Active"
                                      : isArchived
                                      ? "Archived"
                                      : "Inactive",
                                  style: GoogleFonts.cairo(
                                    color: badgeColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11.sp,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            title,
                            style: GoogleFonts.cairo(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          SizedBox(height: 10.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  HugeIcon(
                                    icon: HugeIcons.strokeRoundedUser02,
                                    size: 16.r,
                                    color: mutedColor,
                                  ),
                                  SizedBox(width: 6.w),
                                  Text(
                                    "By: ${createdBy.length > 10 ? createdBy.substring(0, 10) : createdBy}",
                                    style: GoogleFonts.cairo(
                                      fontSize: 12.sp,
                                      color: mutedColor,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  HugeIcon(
                                    icon: HugeIcons.strokeRoundedActivity01,
                                    size: 16.r,
                                    color: Colors.green,
                                  ),
                                  SizedBox(width: 6.w),
                                  Text(
                                    "Attendance: $attendanceCount",
                                    style: GoogleFonts.cairo(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
