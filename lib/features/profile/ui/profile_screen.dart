import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:lottie/lottie.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';
import 'package:platformexamapp/core/widgets/glass_card.dart';
import 'package:platformexamapp/core/widgets/loading_state.dart';
import 'package:platformexamapp/features/auth/data/models/user_data.dart';
import 'package:platformexamapp/features/profile/ui/widgets/attendance_history_view.dart';
import 'package:platformexamapp/features/profile/ui/widgets/profile_qr_dialog.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();

  Future<void> _shareQR(UserData user) async {
    try {
      final image = await _screenshotController.capture();
      if (image != null) {
        final tempDir = await getTemporaryDirectory();
        final file = await File(
          '${tempDir.path}/${user.name ?? "QR"}_attendance_card.png',
        ).create();
        await file.writeAsBytes(image);

        await Share.shareXFiles([
          XFile(file.path),
        ], text: 'Here is my Egtma3na Attendance Card!');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to share card: $e', style: GoogleFonts.cairo()),
          backgroundColor: AppColors.heartRed,
        ),
      );
    }
  }

  Future<void> _saveQR(UserData user) async {
    try {
      final image = await _screenshotController.capture();
      if (image != null) {
        final tempDir = await getTemporaryDirectory();
        final file = await File(
          '${tempDir.path}/${user.name ?? "QR"}_attendance_card.png',
        ).create();
        await file.writeAsBytes(image);

        await Share.shareXFiles([
          XFile(file.path),
        ], text: 'Save my QR Code to Photos/Files');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'system_dialog_save'.tr(),
                style: GoogleFonts.cairo(),
              ),
              backgroundColor: AppColors.successGreen,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to export card: $e',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: AppColors.heartRed,
        ),
      );
    }
  }

  void _openQrFullscreen(UserData userData, String qrPayload) {
    ProfileQrDialog.show(
      context: context,
      user: userData,
      qrPayload: qrPayload,
      onSave: () => _saveQR(userData),
      onShare: () => _shareQR(userData),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageBg = isDark ? AppColors.darkPageBg : AppColors.lightPageBg;
    final textColor = isDark ? AppColors.darkTextMain : AppColors.lightTextMain;
    final surfaceColor = isDark
        ? AppColors.darkSurface
        : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final mutedColor = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;

    final uid = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: pageBg,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios, color: textColor, size: 20.r),
        ),
        title: Text(
          "my_profile".tr(),
          style: GoogleFonts.cairo(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection("users")
            .doc(uid)
            .snapshots(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const LoadingState();
          }

          if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
            return Center(child: Lottie.asset("assets/lottie/not found.json"));
          }

          final userData = UserData.fromJson(
            userSnapshot.data!.data() as Map<String, dynamic>,
            userSnapshot.data!.id,
          );

          final qrPayload = json.encode({
            "uid": userData.uid,
            "name": userData.name,
            "email": userData.email,
            "userId": userData.humanReadableId,
          });

          return Column(
            children: [
              // Profile QR Header Card
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: Screenshot(
                  controller: _screenshotController,
                  child: GlassCard(
                    padding: EdgeInsets.all(16.r),
                    borderRadius: 24.r,
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection("seasons")
                          .where("status", isEqualTo: "active")
                          .limit(1)
                          .snapshots(),
                      builder: (context, seasonSnap) {
                        final seasonName =
                            (seasonSnap.data?.docs.isNotEmpty == true)
                            ? seasonSnap.data!.docs.first["name"] ??
                                  "Default Season"
                            : "No Active Season";

                        return StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection("events")
                              .where("isActive", isEqualTo: true)
                              .limit(1)
                              .snapshots(),
                          builder: (context, eventSnap) {
                            final activeEventId =
                                (eventSnap.data?.docs.isNotEmpty == true)
                                ? eventSnap.data!.docs.first.id
                                : "";

                            return StreamBuilder<DocumentSnapshot>(
                              stream: activeEventId.isNotEmpty
                                  ? FirebaseFirestore.instance
                                        .collection("attendance")
                                        .doc("${activeEventId}_$uid")
                                        .snapshots()
                                  : const Stream<DocumentSnapshot>.empty(),
                              builder: (context, attendanceSnap) {
                                final isPresent =
                                    attendanceSnap.data?.exists == true;
                                final statusText = activeEventId.isEmpty
                                    ? "no_active_meeting_status".tr()
                                    : isPresent
                                    ? "present".tr()
                                    : "absent".tr();
                                final isUnlocked = isPresent;

                                return Column(
                                  children: [
                                    // User Avatar + Details + Tap to Open Large QR
                                    InkWell(
                                      onTap: () => _openQrFullscreen(
                                        userData,
                                        qrPayload,
                                      ),
                                      borderRadius: BorderRadius.circular(16.r),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 28.r,
                                            backgroundColor: AppColors.softGold
                                                .withOpacity(0.15),
                                            backgroundImage:
                                                userData.profileImage != null &&
                                                    userData
                                                        .profileImage!
                                                        .isNotEmpty
                                                ? NetworkImage(
                                                    userData.profileImage!,
                                                  )
                                                : null,
                                            child:
                                                userData.profileImage == null ||
                                                    userData
                                                        .profileImage!
                                                        .isEmpty
                                                ? HugeIcon(
                                                    icon: HugeIcons
                                                        .strokeRoundedUser02,
                                                    size: 28.r,
                                                    color: AppColors.softGold,
                                                  )
                                                : null,
                                          ),
                                          SizedBox(width: 12.w),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  userData.name ?? "User",
                                                  style: GoogleFonts.cairo(
                                                    fontSize: 17.sp,
                                                    fontWeight: FontWeight.bold,
                                                    color: textColor,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                Text(
                                                  userData.email ?? "",
                                                  style: GoogleFonts.cairo(
                                                    fontSize: 12.sp,
                                                    color: mutedColor,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                SizedBox(height: 3.h),
                                                Text(
                                                  "ID: ${userData.humanReadableId ?? 'EGT000000'}",
                                                  style: GoogleFonts.cairo(
                                                    fontSize: 12.sp,
                                                    color: AppColors.softGold,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(width: 8.w),
                                          // Interactive Hero QR Preview
                                          Hero(
                                            tag: 'profile_qr_hero',
                                            child: Container(
                                              padding: EdgeInsets.all(4.r),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(12.r),
                                                border: Border.all(
                                                  color: AppColors.softGold,
                                                  width: 1.5,
                                                ),
                                              ),
                                              child: QrImageView(
                                                data: qrPayload,
                                                version: QrVersions.auto,
                                                size: 58.r,
                                                eyeStyle: const QrEyeStyle(
                                                  eyeShape: QrEyeShape.square,
                                                  color:
                                                      AppColors.cinematicNavy,
                                                ),
                                                dataModuleStyle:
                                                    const QrDataModuleStyle(
                                                      dataModuleShape:
                                                          QrDataModuleShape
                                                              .square,
                                                      color: AppColors
                                                          .cinematicNavy,
                                                    ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Divider(height: 20.h, color: borderColor),

                                    // Statistics Metrics Cards Row
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        _buildCardMetric(
                                          context,
                                          HugeIcons.strokeRoundedChart01,
                                          "attendance".tr(),
                                          "${userData.attendancePercentage ?? 0.0}%",
                                        ),
                                        _buildCardMetric(
                                          context,
                                          HugeIcons.strokeRoundedFire,
                                          "streak".tr(),
                                          "${userData.displayStreak} 🔥",
                                        ),
                                        _buildCardMetric(
                                          context,
                                          HugeIcons.strokeRoundedAward01,
                                          "Highest".tr(),
                                          "${userData.highestStreakVal} 🏆",
                                        ),
                                        _buildCardMetric(
                                          context,
                                          HugeIcons.strokeRoundedCalendar01,
                                          "total_present".tr(),
                                          "${userData.totalAttendance ?? 0}",
                                        ),
                                      ],
                                    ),
                                    Divider(height: 20.h, color: borderColor),

                                    // Season and Status indicators
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "current_season".tr(),
                                              style: GoogleFonts.cairo(
                                                fontSize: 11.sp,
                                                color: mutedColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(height: 2.h),
                                            Row(
                                              children: [
                                                HugeIcon(
                                                  icon: HugeIcons
                                                      .strokeRoundedGrid,
                                                  size: 14.r,
                                                  color: AppColors.softGold,
                                                ),
                                                SizedBox(width: 4.w),
                                                Text(
                                                  seasonName,
                                                  style: GoogleFonts.cairo(
                                                    fontSize: 12.sp,
                                                    fontWeight: FontWeight.bold,
                                                    color: textColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              "todays_status".tr(),
                                              style: GoogleFonts.cairo(
                                                fontSize: 11.sp,
                                                color: mutedColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(height: 2.h),
                                            Row(
                                              children: [
                                                Icon(
                                                  isPresent
                                                      ? Icons.check_circle
                                                      : Icons.cancel,
                                                  size: 14.r,
                                                  color: isPresent
                                                      ? AppColors.successGreen
                                                      : AppColors.heartRed,
                                                ),
                                                SizedBox(width: 4.w),
                                                Text(
                                                  statusText,
                                                  style: GoogleFonts.cairo(
                                                    fontSize: 12.sp,
                                                    fontWeight: FontWeight.bold,
                                                    color: isPresent
                                                        ? AppColors.successGreen
                                                        : AppColors.heartRed,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 10.h),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 6.h,
                                        horizontal: 12.w,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isUnlocked
                                            ? AppColors.successGreen
                                                  .withOpacity(0.12)
                                            : AppColors.softGold.withOpacity(
                                                0.12,
                                              ),
                                        borderRadius: BorderRadius.circular(
                                          12.r,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            isUnlocked
                                                ? Icons.lock_open_rounded
                                                : Icons.lock_outline_rounded,
                                            size: 14.r,
                                            color: isUnlocked
                                                ? AppColors.successGreen
                                                : AppColors.softGold,
                                          ),
                                          SizedBox(width: 6.w),
                                          Text(
                                            isUnlocked
                                                ? "today_content_unlocked".tr()
                                                : "mark_present_to_unlock".tr(),
                                            style: GoogleFonts.cairo(
                                              fontSize: 11.sp,
                                              fontWeight: FontWeight.bold,
                                              color: isUnlocked
                                                  ? AppColors.successGreen
                                                  : AppColors.softGold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),

              // Action Buttons Bar
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _shareQR(userData),
                        icon: HugeIcon(
                          icon: HugeIcons.strokeRoundedShare01,
                          size: 16.r,
                          color: textColor,
                        ),
                        label: Text(
                          "share_qr".tr(),
                          style: GoogleFonts.cairo(
                            fontSize: 13.sp,
                            color: textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark
                              ? AppColors.darkGlassSurface
                              : AppColors.lightGlassSurface,
                          foregroundColor: textColor,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                            side: BorderSide(color: borderColor),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _saveQR(userData),
                        icon: HugeIcon(
                          icon: HugeIcons.strokeRoundedDownload01,
                          size: 16.r,
                          color: textColor,
                        ),
                        label: Text(
                          "save_qr".tr(),
                          style: GoogleFonts.cairo(
                            fontSize: 13.sp,
                            color: textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark
                              ? AppColors.darkGlassSurface
                              : AppColors.lightGlassSurface,
                          foregroundColor: textColor,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                            side: BorderSide(color: borderColor),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 12.h),

              // Attendance Body View
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(28.r),
                      topRight: Radius.circular(28.r),
                    ),
                    border: Border(
                      top: BorderSide(color: borderColor, width: 1),
                    ),
                  ),
                  child: AttendanceHistoryView(uid: uid),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCardMetric(
    BuildContext context,
    List<List<dynamic>> icon,
    String label,
    String value,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextMain : AppColors.lightTextMain;
    final mutedColor = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;

    return Column(
      children: [
        HugeIcon(icon: icon, size: 16.r, color: AppColors.softGold),
        SizedBox(height: 2.h),
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 10.sp,
            color: mutedColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          value,
          style: GoogleFonts.cairo(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ],
    );
  }
}
