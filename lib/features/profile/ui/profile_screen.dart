import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconly/iconly.dart';
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

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final ScreenshotController _screenshotController = ScreenshotController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot> getUserAttempts() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection("examAttempts")
        .where("userId", isEqualTo: uid)
        .snapshots();
  }

  int getTotalScore(List<QueryDocumentSnapshot> docs) {
    int total = 0;
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      total += (data["score"] ?? 0) as int;
    }
    return total;
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

        // On mobile, sharing allows native "Save Image" to gallery or files
        await Share.shareXFiles([
          XFile(file.path),
        ], text: 'Save my QR Code to Photos/Files');
        // EGT000002
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'system_dialog_save'.tr(),
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to export card: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

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
        title: Text("my_profile".tr(), style: const TextStyle(color: Colors.white)),
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

          // Generate QR Payload String
          final qrPayload = json.encode({
            "uid": userData.uid,
            "name": userData.name,
            "email": userData.email,
            "userId": userData.humanReadableId,
          });

          return Column(
            children: [
              // Beautiful QR Card widget wrapped in Screenshot capture
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Screenshot(
                  controller: _screenshotController,
                  child: Container(
                    padding: EdgeInsets.all(16.r),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection("seasons").where("status", isEqualTo: "active").limit(1).snapshots(),
                      builder: (context, seasonSnap) {
                        final seasonName = (seasonSnap.data?.docs.isNotEmpty == true)
                            ? seasonSnap.data!.docs.first["name"] ?? "Default Season"
                            : "No Active Season";

                        return StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance.collection("events").where("isActive", isEqualTo: true).limit(1).snapshots(),
                          builder: (context, eventSnap) {
                            final activeEventId = (eventSnap.data?.docs.isNotEmpty == true)
                                ? eventSnap.data!.docs.first.id
                                : "";

                            return StreamBuilder<DocumentSnapshot>(
                              stream: activeEventId.isNotEmpty
                                  ? FirebaseFirestore.instance.collection("attendance").doc("${activeEventId}_${uid}").snapshots()
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
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 30.r,
                                          backgroundColor: AppColors.primaryColor
                                              .withOpacity(0.1),
                                          backgroundImage:
                                              userData.profileImage != null &&
                                                      userData.profileImage!.isNotEmpty
                                                  ? NetworkImage(userData.profileImage!)
                                                  : null,
                                          child: userData.profileImage == null ||
                                                  userData.profileImage!.isEmpty
                                              ? Icon(
                                                  IconlyLight.user,
                                                  size: 30.r,
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
                                                  fontSize: 18.sp,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              Text(
                                                userData.email ?? "",
                                                style: TextStyle(
                                                  fontSize: 13.sp,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              SizedBox(height: 4.h),
                                              Text(
                                                "ID: ${userData.humanReadableId ?? 'EGT000000'}",
                                                style: TextStyle(
                                                  fontSize: 13.sp,
                                                  color: AppColors.primaryColor,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Small QR View inside card
                                        QrImageView(
                                          data: qrPayload,
                                          version: QrVersions.auto,
                                          size: 70.r,
                                          foregroundColor: AppColors.primaryColor,
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 24),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        _buildCardMetric(
                                          "attendance".tr(),
                                          "${userData.attendancePercentage ?? 0.0}%",
                                        ),
                                        _buildCardMetric(
                                          "streak".tr(),
                                          "${userData.currentStreak ?? 0} 🔥",
                                        ),
                                        _buildCardMetric(
                                          "total_present".tr(),
                                          "${userData.totalAttendance ?? 0}",
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 24),
                                    // Season and Status indicators
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text("current_season".tr(), style: TextStyle(fontSize: 10.sp, color: Colors.grey[500], fontWeight: FontWeight.bold)),
                                            SizedBox(height: 4.h),
                                            Row(
                                              children: [
                                                const Icon(IconlyLight.category, size: 14, color: AppColors.primaryColor),
                                                SizedBox(width: 4.w),
                                                Text(seasonName, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: Colors.black87)),
                                              ],
                                            ),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text("todays_status".tr(), style: TextStyle(fontSize: 10.sp, color: Colors.grey[500], fontWeight: FontWeight.bold)),
                                            SizedBox(height: 4.h),
                                            Row(
                                              children: [
                                                Icon(
                                                  isPresent ? Icons.check_circle : Icons.cancel,
                                                  size: 14,
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
                                    SizedBox(height: 10.h),
                                    Container(
                                      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
                                      decoration: BoxDecoration(
                                        color: isUnlocked ? Colors.green[50] : const Color.fromARGB(255, 84, 77, 54),
                                        borderRadius: BorderRadius.circular(12.r),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            isUnlocked ? Icons.lock_open : Icons.lock,
                                            size: 16,
                                            color: isUnlocked ? Colors.green : Colors.amber[800],
                                          ),
                                          SizedBox(width: 6.w),
                                          Text(
                                            isUnlocked ? "today_content_unlocked".tr() : "mark_present_to_unlock".tr(),
                                            style: TextStyle(
                                              fontSize: 11.sp,
                                              fontWeight: FontWeight.bold,
                                              color: isUnlocked ? Colors.green[800] : Colors.amber[900],
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

              // Action Buttons Row
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _shareQR(userData),
                        icon: const Icon(IconlyLight.send),
                        label: Text("share_qr".tr()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white24,
                          foregroundColor: Colors.white,
                          elevation: 0,
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
                        icon: const Icon(IconlyLight.download),
                        label: Text("save_qr".tr()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white24,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    IconButton(
                      onPressed: () {
                        // Force refresh by rebuilding state
                        setState(() {});
                      },
                      icon: const Icon(
                        IconlyLight.activity,
                        color: Colors.white,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white24,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 15.h),

              // TabBar Selection
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16.w),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  labelColor: AppColors.primaryColor,
                  unselectedLabelColor: Colors.white,
                  tabs: [
                    Tab(text: "attendance".tr()),
                    Tab(text: "exams".tr()),
                  ],
                ),
              ),

              SizedBox(height: 10.h),

              // TabViews inside bottom Container sheet
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30.r),
                      topRight: Radius.circular(30.r),
                    ),
                  ),
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Tab 1: Attendance History
                      AttendanceHistoryView(uid: uid),

                      // Tab 2: Exam Stats
                      StreamBuilder<QuerySnapshot>(
                        stream: getUserAttempts(),
                        builder: (context, examSnapshot) {
                          if (examSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
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

  Widget _buildCardMetric(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12.sp, color: Colors.grey[500]),
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor,
          ),
        ),
      ],
    );
  }
}
