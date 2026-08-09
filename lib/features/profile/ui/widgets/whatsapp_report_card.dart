import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import 'package:platformexamapp/core/theme/app_colors.dart';
import 'package:platformexamapp/core/widgets/glass_card.dart';
import 'package:platformexamapp/features/auth/data/models/user_data.dart';
import 'package:platformexamapp/features/profile/ui/widgets/user_avatar.dart';

class WhatsappReportCard extends StatefulWidget {
  final UserData user;
  final double attendancePct;
  final double absencePct;
  final int totalMeetings;
  final int attended;
  final int missed;
  final int fridayAttended;
  final int fridayTotal;
  final int sundayAttended;
  final int sundayTotal;
  final int currentStreak;
  final int highestStreak;
  final String lastAttendanceDate;

  const WhatsappReportCard({
    super.key,
    required this.user,
    required this.attendancePct,
    required this.absencePct,
    required this.totalMeetings,
    required this.attended,
    required this.missed,
    required this.fridayAttended,
    required this.fridayTotal,
    required this.sundayAttended,
    required this.sundayTotal,
    required this.currentStreak,
    required this.highestStreak,
    required this.lastAttendanceDate,
  });

  static void show(
    BuildContext context, {
    required UserData user,
    required double attendancePct,
    required double absencePct,
    required int totalMeetings,
    required int attended,
    required int missed,
    required int fridayAttended,
    required int fridayTotal,
    required int sundayAttended,
    required int sundayTotal,
    required int currentStreak,
    required int highestStreak,
    required String lastAttendanceDate,
  }) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
        child: WhatsappReportCard(
          user: user,
          attendancePct: attendancePct,
          absencePct: absencePct,
          totalMeetings: totalMeetings,
          attended: attended,
          missed: missed,
          fridayAttended: fridayAttended,
          fridayTotal: fridayTotal,
          sundayAttended: sundayAttended,
          sundayTotal: sundayTotal,
          currentStreak: currentStreak,
          highestStreak: highestStreak,
          lastAttendanceDate: lastAttendanceDate,
        ),
      ),
    );
  }

  @override
  State<WhatsappReportCard> createState() => _WhatsappReportCardState();
}

class _WhatsappReportCardState extends State<WhatsappReportCard> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool isExporting = false;

  Future<void> _shareToWhatsApp() async {
    setState(() => isExporting = true);
    try {
      final image = await _screenshotController.capture();
      if (image != null) {
        final tempDir = await getTemporaryDirectory();
        final file = await File(
          '${tempDir.path}/${widget.user.name ?? "User"}_attendance_report.png',
        ).create();
        await file.writeAsBytes(image);

        final textMsg =
            "📊 Egtma3na Attendance Report for ${widget.user.name ?? 'Member'}\n"
            "• Attendance: ${widget.attendancePct.toStringAsFixed(1)}%\n"
            "• Streak: ${widget.currentStreak} 🔥\n"
            "• Highest Streak: ${widget.highestStreak} 🏆\n"
            "• Total Attended: ${widget.attended} / ${widget.totalMeetings}";

        await Share.shareXFiles([XFile(file.path)], text: textMsg);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Error sharing report: $e",
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: AppColors.heartRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isExporting = false);
    }
  }

  Future<void> _saveAsImage() async {
    setState(() => isExporting = true);
    try {
      final image = await _screenshotController.capture();
      if (image != null) {
        final tempDir = await getTemporaryDirectory();
        final file = await File(
          '${tempDir.path}/${widget.user.name ?? "User"}_attendance_report.png',
        ).create();
        await file.writeAsBytes(image);

        await Share.shareXFiles([
          XFile(file.path),
        ], text: "Save Attendance Report Image");

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Report exported successfully!",
                style: GoogleFonts.cairo(),
              ),
              backgroundColor: AppColors.successGreen,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error saving image: $e", style: GoogleFonts.cairo()),
            backgroundColor: AppColors.heartRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextMain : AppColors.lightTextMain;
    final mutedColor = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Printable Report Card wrapped in Screenshot
        Screenshot(
          controller: _screenshotController,
          child: GlassCard(
            padding: EdgeInsets.all(20.r),
            borderRadius: 28.r,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Header: Church Logo & App Name
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(6.r),
                          decoration: const BoxDecoration(
                            color: AppColors.softGold,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.church_rounded,
                            color: AppColors.cinematicNavy,
                            size: 18.r,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          "Egtma3na • إجتماعنا",
                          style: GoogleFonts.cairo(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.softGold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.softGold.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: AppColors.softGold.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        "Attendance Report",
                        style: GoogleFonts.cairo(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.softGold,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16.h),
                Divider(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  height: 1,
                ),
                SizedBox(height: 16.h),

                // User Info Row
                Row(
                  children: [
                    UserAvatar(
                      imageUrl: widget.user.profileImage,
                      radius: 30.r,
                      border: Border.all(color: AppColors.softGold, width: 2),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.user.name ?? "Member Name",
                            style: GoogleFonts.cairo(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            "ID: ${widget.user.humanReadableId ?? 'EGT000'}",
                            style: GoogleFonts.cairo(
                              fontSize: 12.sp,
                              color: AppColors.softGold,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(10.r),
                      decoration: BoxDecoration(
                        color: AppColors.successGreen.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: AppColors.successGreen.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            "${widget.attendancePct.toStringAsFixed(0)}%",
                            style: GoogleFonts.cairo(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.successGreen,
                            ),
                          ),
                          Text(
                            "Attendance",
                            style: GoogleFonts.cairo(
                              fontSize: 9.sp,
                              color: AppColors.successGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16.h),

                // Statistics Grid Inside Report
                Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkGlassSurface
                        : AppColors.lightGlassSurface,
                    borderRadius: BorderRadius.circular(18.r),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildReportStatTile(
                            context,
                            "Total Meetings",
                            "${widget.totalMeetings}",
                            AppColors.softGold,
                          ),
                          _buildReportStatTile(
                            context,
                            "Attended",
                            "${widget.attended}",
                            AppColors.successGreen,
                          ),
                          _buildReportStatTile(
                            context,
                            "Missed",
                            "${widget.missed}",
                            AppColors.heartRed,
                          ),
                        ],
                      ),
                      Divider(
                        height: 16.h,
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildReportStatTile(
                            context,
                            "Friday Meeting",
                            "${widget.fridayAttended}/${widget.fridayTotal}",
                            AppColors.softGold,
                          ),
                          _buildReportStatTile(
                            context,
                            "Sunday Activity",
                            "${widget.sundayAttended}/${widget.sundayTotal}",
                            Colors.orange,
                          ),
                          _buildReportStatTile(
                            context,
                            "Absence %",
                            "${widget.absencePct.toStringAsFixed(0)}%",
                            AppColors.heartRed,
                          ),
                        ],
                      ),
                      Divider(
                        height: 16.h,
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildReportStatTile(
                            context,
                            "Current Streak",
                            "${widget.currentStreak} 🔥",
                            AppColors.softGold,
                          ),
                          _buildReportStatTile(
                            context,
                            "Highest Streak",
                            "${widget.highestStreak} 🏆",
                            Colors.purple.shade300,
                          ),
                          _buildReportStatTile(
                            context,
                            "Last Attended",
                            widget.lastAttendanceDate,
                            Colors.teal.shade300,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 14.h),

                // Footer Watermark
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.verified, size: 14.r, color: AppColors.softGold),
                    SizedBox(width: 4.w),
                    Text(
                      "Generated by Egtma3na Platform",
                      style: GoogleFonts.cairo(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                        color: mutedColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: 16.h),

        // Action Buttons Row
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: isExporting ? null : _saveAsImage,
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedDownload01,
                  size: 18.r,
                  color: textColor,
                ),
                label: Text(
                  "save_as_image".tr(),
                  style: GoogleFonts.cairo(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark
                      ? AppColors.darkGlassSurface
                      : AppColors.lightGlassSurface,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                    side: BorderSide(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                    ),
                  ),
                  elevation: 2,
                ),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: isExporting ? null : _shareToWhatsApp,
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedShare01,
                  size: 18.r,
                  color: Colors.white,
                ),
                label: Text(
                  "share_to_whatsapp".tr(),
                  style: GoogleFonts.cairo(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.whatsappGreen,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReportStatTile(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;

    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.cairo(fontSize: 10.sp, color: mutedColor),
        ),
        SizedBox(height: 2.h),
        Text(
          value,
          style: GoogleFonts.cairo(
            fontSize: 13.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
