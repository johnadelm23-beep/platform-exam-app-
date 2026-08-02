import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:lottie/lottie.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';
import 'package:platformexamapp/features/auth/data/models/user_data.dart';
import 'package:platformexamapp/features/profile/ui/widgets/attendance_history_view.dart';
import 'package:platformexamapp/features/profile/ui/widgets/custom_body_container.dart';
import 'package:platformexamapp/features/profile/ui/widgets/profile_qr_dialog.dart';
import 'package:platformexamapp/features/profile/ui/widgets/segmented_tab_bar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  late PageController _pageController;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot> getUserAttempts() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? "";
    return FirebaseFirestore.instance
        .collection("examAttempts")
        .where("userId", isEqualTo: uid)
        .snapshots();
  }

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
          content: Text('Failed to share card: $e'),
          backgroundColor: Colors.red,
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
              content: Text('system_dialog_save'.tr()),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to export card: $e'),
          backgroundColor: Colors.red,
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
    final uid = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.whiteColor),
        ),
        title: Text(
          "my_profile".tr(),
          style: TextStyle(
            color: Colors.white,
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
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
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
                  child: Container(
                    padding: EdgeInsets.all(16.r),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection("seasons")
                          .where("status", isEqualTo: "active")
                          .limit(1)
                          .snapshots(),
                      builder: (context, seasonSnap) {
                        final seasonName = (seasonSnap.data?.docs.isNotEmpty == true)
                            ? seasonSnap.data!.docs.first["name"] ?? "Default Season"
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
                                final isPresent = attendanceSnap.data?.exists == true;
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
                                      onTap: () => _openQrFullscreen(userData, qrPayload),
                                      borderRadius: BorderRadius.circular(16.r),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 28.r,
                                            backgroundColor: AppColors.primaryColor
                                                .withValues(alpha: 0.1),
                                            backgroundImage:
                                                userData.profileImage != null &&
                                                        userData.profileImage!.isNotEmpty
                                                    ? NetworkImage(userData.profileImage!)
                                                    : null,
                                            child: userData.profileImage == null ||
                                                    userData.profileImage!.isEmpty
                                                ? HugeIcon(
                                                    icon: HugeIcons.strokeRoundedUser02,
                                                    size: 28.r,
                                                    color: AppColors.primaryColor,
                                                  )
                                                : null,
                                          ),
                                          SizedBox(width: 12.w),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  userData.name ?? "User",
                                                  style: TextStyle(
                                                    fontSize: 17.sp,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black87,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                Text(
                                                  userData.email ?? "",
                                                  style: TextStyle(
                                                    fontSize: 12.sp,
                                                    color: Colors.grey[600],
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                SizedBox(height: 3.h),
                                                Text(
                                                  "ID: ${userData.humanReadableId ?? 'EGT000000'}",
                                                  style: TextStyle(
                                                    fontSize: 12.sp,
                                                    color: AppColors.primaryColor,
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
                                                borderRadius: BorderRadius.circular(10.r),
                                                border: Border.all(
                                                  color: AppColors.primaryColor.withValues(alpha: 0.2),
                                                ),
                                              ),
                                              child: QrImageView(
                                                data: qrPayload,
                                                version: QrVersions.auto,
                                                size: 58.r,
                                                eyeStyle: const QrEyeStyle(
                                                  eyeShape: QrEyeShape.square,
                                                  color: AppColors.primaryColor,
                                                ),
                                                dataModuleStyle: const QrDataModuleStyle(
                                                  dataModuleShape: QrDataModuleShape.square,
                                                  color: AppColors.primaryColor,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Divider(height: 20.h, color: Colors.grey[200]),

                                    // Statistics Metrics Cards Row
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        _buildCardMetric(
                                          HugeIcons.strokeRoundedChart01,
                                          "attendance".tr(),
                                          "${userData.attendancePercentage ?? 0.0}%",
                                        ),
                                        _buildCardMetric(
                                          HugeIcons.strokeRoundedFire,
                                          "streak".tr(),
                                          "${userData.displayStreak} 🔥",
                                        ),
                                        _buildCardMetric(
                                          HugeIcons.strokeRoundedAward01,
                                          "Highest".tr(),
                                          "${userData.highestStreakVal} 🏆",
                                        ),
                                        _buildCardMetric(
                                          HugeIcons.strokeRoundedCalendar01,
                                          "total_present".tr(),
                                          "${userData.totalAttendance ?? 0}",
                                        ),
                                      ],
                                    ),
                                    Divider(height: 20.h, color: Colors.grey[200]),

                                    // Season and Status indicators
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "current_season".tr(),
                                              style: TextStyle(
                                                fontSize: 10.sp,
                                                color: Colors.grey[500],
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(height: 2.h),
                                            Row(
                                              children: [
                                                HugeIcon(
                                                  icon: HugeIcons.strokeRoundedGrid,
                                                  size: 14.r,
                                                  color: AppColors.primaryColor,
                                                ),
                                                SizedBox(width: 4.w),
                                                Text(
                                                  seasonName,
                                                  style: TextStyle(
                                                    fontSize: 12.sp,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              "todays_status".tr(),
                                              style: TextStyle(
                                                fontSize: 10.sp,
                                                color: Colors.grey[500],
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(height: 2.h),
                                            Row(
                                              children: [
                                                Icon(
                                                  isPresent ? Icons.check_circle : Icons.cancel,
                                                  size: 14.r,
                                                  color: isPresent ? Colors.green : Colors.red,
                                                ),
                                                SizedBox(width: 4.w),
                                                Text(
                                                  statusText,
                                                  style: TextStyle(
                                                    fontSize: 12.sp,
                                                    fontWeight: FontWeight.bold,
                                                    color: isPresent ? Colors.green[800] : Colors.red[800],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8.h),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 6.h,
                                        horizontal: 12.w,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isUnlocked
                                            ? Colors.green.withValues(alpha: 0.1)
                                            : Colors.amber.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12.r),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            isUnlocked ? Icons.lock_open : Icons.lock,
                                            size: 14.r,
                                            color: isUnlocked ? Colors.green : Colors.amber[800],
                                          ),
                                          SizedBox(width: 6.w),
                                          Text(
                                            isUnlocked
                                                ? "today_content_unlocked".tr()
                                                : "mark_present_to_unlock".tr(),
                                            style: TextStyle(
                                              fontSize: 11.sp,
                                              fontWeight: FontWeight.bold,
                                              color: isUnlocked
                                                  ? Colors.green[800]
                                                  : Colors.amber[900],
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
                        icon: HugeIcon(icon: HugeIcons.strokeRoundedShare01, size: 16.r, color: Colors.white),
                        label: Text("share_qr".tr(), style: TextStyle(fontSize: 13.sp)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _saveQR(userData),
                        icon: HugeIcon(icon: HugeIcons.strokeRoundedDownload01, size: 16.r, color: Colors.white),
                        label: Text("save_qr".tr(), style: TextStyle(fontSize: 13.sp)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    IconButton(
                      onPressed: () => setState(() {}),
                      icon: HugeIcon(
                        icon: HugeIcons.strokeRoundedActivity01,
                        color: Colors.white,
                        size: 18.r,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 12.h),

              // Premium Segmented Tab Bar
              SegmentedTabBar(
                selectedIndex: _selectedTabIndex,
                onTabChanged: (index) {
                  setState(() {
                    _selectedTabIndex = index;
                  });
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                  );
                },
              ),

              SizedBox(height: 10.h),

              // Bottom Sheet Container containing PageView
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(28.r),
                      topRight: Radius.circular(28.r),
                    ),
                  ),
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _selectedTabIndex = index;
                      });
                    },
                    children: [
                      // Tab 1: Attendance History
                      AttendanceHistoryView(uid: uid),

                      // Tab 2: Exam Stats
                      StreamBuilder<QuerySnapshot>(
                        stream: getUserAttempts(),
                        builder: (context, examSnapshot) {
                          if (examSnapshot.connectionState == ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(color: AppColors.primaryColor),
                            );
                          }
                          final docs = examSnapshot.data?.docs ?? [];
                          if (docs.isEmpty) {
                            return Center(
                              child: Lottie.asset(
                                "assets/lottie/not found.json",
                              ),
                            );
                          }
                          return CustomBodyContainer(docs: docs);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCardMetric(List<List<dynamic>> icon, String label, String value) {
    return Column(
      children: [
        HugeIcon(icon: icon, size: 14.r, color: AppColors.primaryColor),
        SizedBox(height: 2.h),
        Text(
          label,
          style: TextStyle(fontSize: 10.sp, color: Colors.grey[500]),
        ),
        SizedBox(height: 2.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor,
          ),
        ),
      ],
    );
  }
}
