import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconly/iconly.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';
import 'package:platformexamapp/core/services/offline_sync_service.dart';
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
      // Simple offline check
      // Wait, we can test using firestore metadata or dynamic ping
      // Let's use simple offline check via Firestore snap or connection timeout
      final firestore = FirebaseFirestore.instance;
      // We set short timeout
      await firestore.collection("metadata").doc("counters").get().timeout(
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
    
    // Check if scanValue is JSON formatted (uid, name, email, userId)
    try {
      final Map<String, dynamic> data = json.decode(scanValue);
      scannedUid = (data['uid'] ?? '').toString();
      scannedManualId = (data['userId'] ?? '').toString();
    } catch (_) {
      // Not JSON, assume scanValue is raw uid
      scannedUid = scanValue;
    }

    if (scannedUid.isEmpty && scannedManualId.isEmpty) {
      _showErrorDialog("invalid_qr_code".tr(), "invalid_qr_code_desc".tr());
      return;
    }

    _loadAndConfirmUser(uid: scannedUid, manualId: scannedManualId);
  }

  Future<void> _loadAndConfirmUser({String uid = "", String manualId = ""}) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    try {
      DocumentSnapshot? userDoc;
      if (uid.isNotEmpty) {
        userDoc = await FirebaseFirestore.instance.collection("users").doc(uid).get();
      }
      
      // If user doc not found by UID, search by manual ID
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

      // Fallback search by general input if uid is input directly (manual text search)
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

      final userData = UserData.fromJson(userDoc.data() as Map<String, dynamic>, userDoc.id);
      _showConfirmationSheet(userData);

    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showErrorDialog("error_loading_user".tr(), "error_loading_user_desc".tr(args: [e.toString()]));
    }
  }

  Future<void> _showConfirmationSheet(UserData user) async {
    // Fetch Active Event
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
        activeEventData = activeEventSnap.docs.first.data() as Map<String, dynamic>;
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
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30.r),
                topRight: Radius.circular(30.r),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40.w,
                  height: 4.h,
                  margin: EdgeInsets.only(bottom: 15.h),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                Text(
                  "confirm_attendance".tr(),
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                ),
                SizedBox(height: 15.h),
                CircleAvatar(
                  radius: 40.r,
                  backgroundColor: AppColors.primaryColor.withOpacity(0.1),
                  backgroundImage: user.profileImage != null && user.profileImage!.isNotEmpty
                      ? NetworkImage(user.profileImage!)
                      : null,
                  child: user.profileImage == null || user.profileImage!.isEmpty
                      ? Icon(IconlyLight.user, size: 40.r, color: AppColors.primaryColor)
                      : null,
                ),
                SizedBox(height: 10.h),
                Text(
                  user.name ?? "Unknown Name",
                  style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                ),
                Text(
                  user.email ?? "No Email",
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                ),
                SizedBox(height: 15.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCol("manual_id".tr(), user.humanReadableId ?? "N/A"),
                    _buildStatCol("streak".tr(), "${user.currentStreak ?? 0} 🔥"),
                    _buildStatCol("attendance".tr(), "${user.attendancePercentage ?? 0.0}%"),
                  ],
                ),
                const Divider(height: 25),
                Container(
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Row(
                    children: [
                      const Icon(IconlyLight.calendar, color: AppColors.primaryColor),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "todays_meeting".tr(),
                              style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                            ),
                            Text(
                              activeEventTitle,
                              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _resumeScanning();
                        },
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: Text("cancel".tr()),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: activeEventId.isEmpty
                            ? null
                            : () => _confirmAttendance(
                                  userId: user.uid!,
                                  eventId: activeEventId,
                                  dayType: activeEventDayType,
                                ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: Text("confirm".tr()),
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

  Widget _buildStatCol(String title, String val) {
    return Column(
      children: [
        Text(title, style: TextStyle(fontSize: 12.sp, color: Colors.grey[500])),
        SizedBox(height: 4.h),
        Text(val, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Future<void> _confirmAttendance({
    required String userId,
    required String eventId,
    required String dayType,
  }) async {
    Navigator.pop(context); // Close Confirmation Sheet

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    await _checkInternetConnection();
    final String adminId = "admin_placeholder"; // Replace with real admin UID or currentUser.uid

    if (mounted) Navigator.pop(context); // Close Loading

    if (_isOffline) {
      await OfflineSyncService.queueAttendance(
        userId: userId,
        eventId: eventId,
        adminId: adminId,
        dayType: dayType,
      );
      _showSuccessDialog("attendance_queued".tr(), "attendance_queued_desc".tr());
    } else {
      // Online write
      final docId = "${eventId}_$userId";
      final docRef = FirebaseFirestore.instance.collection("attendance").doc(docId);

      try {
        final docSnap = await docRef.get();
        if (docSnap.exists) {
          _showErrorDialog("duplicate_scan".tr(), "duplicate_scan_desc".tr());
          return;
        }

        final userRef = FirebaseFirestore.instance.collection("users").doc(userId);
        final userSnap = await userRef.get();
        
        int currentStreak = 1;
        int longestStreak = 1;

        if (userSnap.exists) {
          final userData = userSnap.data() as Map<String, dynamic>;
          currentStreak = (userData["currentStreak"] ?? 0) + 1;
          longestStreak = (userData["longestStreak"] ?? 0) as int;
        }

        if (currentStreak > longestStreak) {
          longestStreak = currentStreak;
        }

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
          "longestStreak": longestStreak,
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
        // Sync any queued items background
        OfflineSyncService.syncQueue();
      } catch (e) {
        _showErrorDialog("confirmation_failed".tr(), "confirmation_failed_desc".tr(args: [e.toString()]));
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
      icon: Icons.check_circle,
      iconColor: Colors.green,
      title: title,
      description: body,
      confirmText: "ok".tr(),
      confirmButtonColor: Colors.green,
      onConfirm: () {
        Navigator.pop(context);
        _resumeScanning();
      },
    );
  }

  void _showErrorDialog(String title, String body) {
    AppDialog.show(
      context: context,
      icon: Icons.error,
      iconColor: Colors.red,
      title: title,
      description: body,
      confirmText: "retry".tr(),
      confirmButtonColor: Colors.red,
      onConfirm: () {
        Navigator.pop(context);
        _resumeScanning();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingPermission) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (!_isPermissionGranted) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24.r),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.camera_alt_outlined, size: 64.r, color: Colors.white),
                SizedBox(height: 16.h),
                Text(
                  "camera_permission_required".tr(),
                  style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8.h),
                Text(
                  "camera_permission_desc".tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[400], fontSize: 14.sp),
                ),
                SizedBox(height: 24.h),
                ElevatedButton(
                  onPressed: _checkPermission,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                  ),
                  child: Text("grant_permission".tr(), style: const TextStyle(color: Colors.white)),
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
        title: Text("attendance_scanner".tr(), style: const TextStyle(color: Colors.white)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _isFlashOn ? Icons.flash_on : Icons.flash_off,
              color: Colors.white,
            ),
            onPressed: () {
              _scannerController.toggleTorch();
              setState(() {
                _isFlashOn = !_isFlashOn;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
            onPressed: () {
              _scannerController.switchCamera();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera scanner
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
          ),

          // QR Box Target Overlay
          Center(
            child: Container(
              width: 250.w,
              height: 250.h,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green, width: 3),
                borderRadius: BorderRadius.circular(16.r),
              ),
            ),
          ),

          // Resume Scanning overlay button
          if (_isScanningPaused)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: ElevatedButton.icon(
                    onPressed: _resumeScanning,
                    icon: const Icon(Icons.play_arrow),
                    label: Text("resume_scanner".tr()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                    ),
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
                  color: Colors.orange.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_off, color: Colors.white),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        "offline_mode_warning".tr(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(25.r),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: "enter_manual_id".tr(),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(IconlyLight.search, color: AppColors.primaryColor),
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
