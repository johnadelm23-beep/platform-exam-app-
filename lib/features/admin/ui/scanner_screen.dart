import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';
import 'package:platformexamapp/core/services/offline_sync_service.dart';
import 'package:platformexamapp/core/widgets/glass_card.dart';
import 'package:platformexamapp/core/widgets/gold_button.dart';
import 'package:platformexamapp/features/auth/data/models/user_data.dart';
import 'package:platformexamapp/core/widgets/app_dialog.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  final TextEditingController _searchController = TextEditingController();
  bool _isPermissionGranted = false;
  bool _isCheckingPermission = true;
  bool _isScanningPaused = false;
  bool _isFlashOn = false;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
    _checkInternetConnection();
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.camera.status;
    if (status.isGranted) {
      setState(() {
        _isPermissionGranted = true;
        _isCheckingPermission = false;
      });
    } else {
      final request = await Permission.camera.request();
      setState(() {
        _isPermissionGranted = request.isGranted;
        _isCheckingPermission = false;
      });
    }
  }

  Future<void> _checkInternetConnection() async {
    try {
      final firestore = FirebaseFirestore.instance;
      await firestore
          .collection("metadata")
          .doc("counters")
          .get()
          .timeout(
            const Duration(seconds: 2),
            onTimeout: () {
              setState(() {
                _isOffline = true;
              });
              throw Exception("Offline");
            },
          );
      setState(() {
        _isOffline = false;
      });
    } catch (_) {
      setState(() {
        _isOffline = true;
      });
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isScanningPaused) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? rawValue = barcodes.first.rawValue;
      if (rawValue != null && rawValue.isNotEmpty) {
        setState(() {
          _isScanningPaused = true;
        });
        _processScan(rawValue);
      }
    }
  }

  Future<void> _processScan(String scanValue) async {
    String scannedUid = "";
    String scannedManualId = "";

    try {
      final Map<String, dynamic> data = json.decode(scanValue);
      scannedUid = (data['uid'] ?? '').toString();
      scannedManualId = (data['userId'] ?? '').toString();
    } catch (_) {
      scannedUid = scanValue;
    }

    if (scannedUid.isEmpty && scannedManualId.isEmpty) {
      _showErrorDialog("invalid_qr_code".tr(), "invalid_qr_code_desc".tr());
      return;
    }

    _loadAndConfirmUser(uid: scannedUid, manualId: scannedManualId);
  }

  Future<void> _loadAndConfirmUser({
    String uid = "",
    String manualId = "",
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.softGold),
      ),
    );

    try {
      DocumentSnapshot? userDoc;
      if (uid.isNotEmpty) {
        userDoc = await FirebaseFirestore.instance
            .collection("users")
            .doc(uid)
            .get();
      }

      if ((userDoc == null || !userDoc.exists) && manualId.isNotEmpty) {
        final query = await FirebaseFirestore.instance
            .collection("users")
            .where("humanReadableId", isEqualTo: manualId)
            .limit(1)
            .get();
        if (query.docs.isNotEmpty) {
          userDoc = query.docs.first;
        }
      }

      if ((userDoc == null || !userDoc.exists) && uid.isNotEmpty) {
        final query = await FirebaseFirestore.instance
            .collection("users")
            .where("humanReadableId", isEqualTo: uid)
            .limit(1)
            .get();
        if (query.docs.isNotEmpty) {
          userDoc = query.docs.first;
        }
      }

      if (mounted) Navigator.pop(context); // Close loading dialog

      if (userDoc == null || !userDoc.exists) {
        _showErrorDialog("user_not_found".tr(), "user_not_found_desc".tr());
        return;
      }

      final userData = UserData.fromJson(
        userDoc.data() as Map<String, dynamic>,
        userDoc.id,
      );
      _showConfirmationSheet(userData);
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showErrorDialog(
        "error_loading_user".tr(),
        "error_loading_user_desc".tr(args: [e.toString()]),
      );
    }
  }

  Future<void> _showConfirmationSheet(UserData user) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textColor = isDark ? AppColors.darkTextMain : AppColors.lightTextMain;
    final mutedColor = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;

    QuerySnapshot? activeEventSnap;
    Map<String, dynamic>? activeEventData;
    String activeEventId = "";
    String activeEventTitle = "No Active Event";
    String activeEventDayType = "custom_event";

    try {
      activeEventSnap = await FirebaseFirestore.instance
          .collection("events")
          .where("isActive", isEqualTo: true)
          .limit(1)
          .get();
      if (activeEventSnap.docs.isNotEmpty) {
        activeEventData =
            activeEventSnap.docs.first.data() as Map<String, dynamic>;
        activeEventId = activeEventSnap.docs.first.id;
        activeEventTitle = activeEventData["title"] ?? "Active Event";
        activeEventDayType = activeEventData["type"] ?? "custom_event";
      }
    } catch (_) {}

    if (mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return Container(
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color: surfaceBg,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32.r),
                topRight: Radius.circular(32.r),
              ),
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40.w,
                  height: 4.h,
                  margin: EdgeInsets.only(bottom: 16.h),
                  decoration: BoxDecoration(
                    color: mutedColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                Text(
                  "confirm_attendance".tr(),
                  style: GoogleFonts.cairo(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.softGold,
                  ),
                ),
                SizedBox(height: 16.h),
                CircleAvatar(
                  radius: 40.r,
                  backgroundColor: AppColors.softGold.withOpacity(0.15),
                  backgroundImage:
                      user.profileImage != null && user.profileImage!.isNotEmpty
                      ? NetworkImage(user.profileImage!)
                      : null,
                  child: user.profileImage == null || user.profileImage!.isEmpty
                      ? HugeIcon(
                          icon: HugeIcons.strokeRoundedUser02,
                          size: 40.r,
                          color: AppColors.softGold,
                        )
                      : null,
                ),
                SizedBox(height: 12.h),
                Text(
                  user.name ?? "Unknown Name",
                  style: GoogleFonts.cairo(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                Text(
                  user.email ?? "No Email",
                  style: GoogleFonts.cairo(fontSize: 13.sp, color: mutedColor),
                ),
                SizedBox(height: 16.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCol(
                      "manual_id".tr(),
                      user.humanReadableId ?? "N/A",
                      textColor,
                      mutedColor,
                    ),
                    _buildStatCol(
                      "streak".tr(),
                      "${user.currentStreak ?? 0} 🔥",
                      textColor,
                      mutedColor,
                    ),
                    _buildStatCol(
                      "attendance".tr(),
                      "${user.attendancePercentage ?? 0.0}%",
                      textColor,
                      mutedColor,
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                Divider(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
                SizedBox(height: 12.h),
                GlassCard(
                  padding: EdgeInsets.all(12.r),
                  borderRadius: 16.r,
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: AppColors.softGold.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const HugeIcon(
                          icon: HugeIcons.strokeRoundedCalendar01,
                          color: AppColors.softGold,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "todays_meeting".tr(),
                              style: GoogleFonts.cairo(
                                fontSize: 12.sp,
                                color: mutedColor,
                              ),
                            ),
                            Text(
                              activeEventTitle,
                              style: GoogleFonts.cairo(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _resumeScanning();
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                          ),
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                        ),
                        child: Text(
                          "cancel".tr(),
                          style: GoogleFonts.cairo(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: GoldButton(
                        title: "confirm".tr(),
                        onPressed: activeEventId.isEmpty
                            ? null
                            : () => _confirmAttendance(
                                userId: user.uid!,
                                eventId: activeEventId,
                                dayType: activeEventDayType,
                              ),
                        height: 48.h,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    }
  }

  Widget _buildStatCol(
    String title,
    String val,
    Color textColor,
    Color mutedColor,
  ) {
    return Column(
      children: [
        Text(
          title,
          style: GoogleFonts.cairo(fontSize: 11.sp, color: mutedColor),
        ),
        SizedBox(height: 2.h),
        Text(
          val,
          style: GoogleFonts.cairo(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Future<void> _confirmAttendance({
    required String userId,
    required String eventId,
    required String dayType,
  }) async {
    Navigator.pop(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.softGold),
      ),
    );

    await _checkInternetConnection();
    final String adminId = "admin_placeholder";

    if (mounted) Navigator.pop(context);

    if (_isOffline) {
      await OfflineSyncService.queueAttendance(
        userId: userId,
        eventId: eventId,
        adminId: adminId,
        dayType: dayType,
      );
      _showSuccessDialog(
        "attendance_queued".tr(),
        "attendance_queued_desc".tr(),
      );
    } else {
      final docId = "${eventId}_$userId";
      final docRef = FirebaseFirestore.instance
          .collection("attendance")
          .doc(docId);

      try {
        final docSnap = await docRef.get();
        if (docSnap.exists) {
          _showErrorDialog("duplicate_scan".tr(), "duplicate_scan_desc".tr());
          return;
        }

        final userRef = FirebaseFirestore.instance
            .collection("users")
            .doc(userId);
        final userSnap = await userRef.get();

        final streakResult = OfflineSyncService.calculateStreakUpdate(
          userDataMap: userSnap.exists
              ? userSnap.data() as Map<String, dynamic>
              : null,
          now: DateTime.now(),
        );
        final currentStreak = streakResult["currentStreak"]!;
        final highestStreak = streakResult["highestStreak"]!;

        final seasonId = await OfflineSyncService.getActiveSeasonId();
        final batch = FirebaseFirestore.instance.batch();

        batch.set(docRef, {
          "id": docId,
          "userId": userId,
          "eventId": eventId,
          "adminId": adminId,
          "timestamp": FieldValue.serverTimestamp(),
          "dayType": dayType,
          "seasonId": seasonId,
        });

        final Map<String, dynamic> userUpdates = {
          "totalAttendance": FieldValue.increment(1),
          "currentStreak": currentStreak,
          "longestStreak": highestStreak,
          "highestStreak": highestStreak,
          "lastAttendanceDate": FieldValue.serverTimestamp(),
        };

        if (dayType == "friday_meeting") {
          userUpdates["fridayAttendanceCount"] = FieldValue.increment(1);
        } else if (dayType == "sunday_activity") {
          userUpdates["sundayAttendanceCount"] = FieldValue.increment(1);
        }

        batch.update(userRef, userUpdates);

        await batch.commit();

        await OfflineSyncService.recalculateAttendancePercentage(userId);

        _showSuccessDialog("attendance_confirmed".tr(), "success".tr());
        OfflineSyncService.syncQueue();
      } catch (e) {
        _showErrorDialog(
          "confirmation_failed".tr(),
          "confirmation_failed_desc".tr(args: [e.toString()]),
        );
      }
    }
  }

  void _resumeScanning() {
    setState(() {
      _isScanningPaused = false;
    });
  }

  void _showSuccessDialog(String title, String body) {
    AppDialog.show(
      context: context,
      iconWidget: Icon(
        Icons.check_circle_rounded,
        color: AppColors.successGreen,
        size: 36.r,
      ),
      iconColor: AppColors.successGreen,
      title: title,
      description: body,
      confirmText: "ok".tr(),
      confirmButtonColor: AppColors.successGreen,
      onConfirm: () {
        Navigator.pop(context);
        _resumeScanning();
      },
    );
  }

  void _showErrorDialog(String title, String body) {
    AppDialog.show(
      context: context,
      iconWidget: Icon(
        Icons.error_outline_rounded,
        color: AppColors.heartRed,
        size: 36.r,
      ),
      iconColor: AppColors.heartRed,
      title: title,
      description: body,
      confirmText: "retry".tr(),
      confirmButtonColor: AppColors.heartRed,
      onConfirm: () {
        Navigator.pop(context);
        _resumeScanning();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageBg = isDark ? AppColors.darkPageBg : AppColors.lightPageBg;

    if (_isCheckingPermission) {
      return Scaffold(
        backgroundColor: pageBg,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.softGold),
        ),
      );
    }

    if (!_isPermissionGranted) {
      return Scaffold(
        backgroundColor: pageBg,
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24.r),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.camera_alt_outlined,
                  size: 64.r,
                  color: AppColors.softGold,
                ),
                SizedBox(height: 16.h),
                Text(
                  "camera_permission_required".tr(),
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  "camera_permission_desc".tr(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    color: AppColors.darkTextMuted,
                    fontSize: 14.sp,
                  ),
                ),
                SizedBox(height: 24.h),
                GoldButton(
                  title: "grant_permission".tr(),
                  onPressed: _checkPermission,
                  width: 200.w,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        ),
        title: Text(
          "attendance_scanner".tr(),
          style: GoogleFonts.cairo(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _isFlashOn ? Icons.flash_on : Icons.flash_off,
              color: AppColors.softGold,
            ),
            onPressed: () {
              _scannerController.toggleTorch();
              setState(() {
                _isFlashOn = !_isFlashOn;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios, color: AppColors.softGold),
            onPressed: () {
              _scannerController.switchCamera();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera scanner
          MobileScanner(controller: _scannerController, onDetect: _onDetect),

          // QR Box Target Overlay
          Center(
            child: Container(
              width: 250.w,
              height: 250.h,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.softGold, width: 3),
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: const [
                  BoxShadow(color: Color(0x66D4AF37), blurRadius: 20),
                ],
              ),
            ),
          ),

          // Resume Scanning overlay button
          if (_isScanningPaused)
            Positioned.fill(
              child: Container(
                color: Colors.black,
                child: Center(
                  child: GoldButton(
                    title: "resume_scanner".tr(),
                    icon: Icons.play_arrow_rounded,
                    onPressed: _resumeScanning,
                    width: 200.w,
                  ),
                ),
              ),
            ),

          // Offline Warning Banner
          if (_isOffline)
            Positioned(
              top: 10.h,
              left: 10.w,
              right: 10.w,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_off, color: Colors.white),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        "offline_mode_warning".tr(),
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Manual ID Input lookup at bottom
          Positioned(
            bottom: 30.h,
            left: 16.w,
            right: 16.w,
            child: GlassCard(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
              borderRadius: 25.r,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: GoogleFonts.cairo(
                        color: isDark
                            ? AppColors.darkTextMain
                            : AppColors.lightTextMain,
                      ),
                      decoration: InputDecoration(
                        hintText: "enter_manual_id".tr(),
                        hintStyle: GoogleFonts.cairo(
                          color: isDark
                              ? AppColors.darkTextCaption
                              : AppColors.lightTextCaption,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedSearch01,
                      color: AppColors.softGold,
                    ),
                    onPressed: () {
                      final val = _searchController.text.trim();
                      if (val.isNotEmpty) {
                        setState(() {
                          _isScanningPaused = true;
                        });
                        _loadAndConfirmUser(uid: val);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
