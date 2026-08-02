import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconly/iconly.dart';
import 'package:platformexamapp/core/widgets/app_dialog.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';

class DailyContentHistoryScreen extends StatefulWidget {
  const DailyContentHistoryScreen({super.key});

  @override
  State<DailyContentHistoryScreen> createState() => _DailyContentHistoryScreenState();
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
    AppDialog.show(
      context: context,
      icon: Icons.delete_forever,
      iconColor: Colors.red,
      title: "Clear Content History",
      description: "This will permanently delete all archived daily content. Active content will never be deleted. This action cannot be undone. Do you wish to proceed?",
      confirmText: "Clear History",
      confirmButtonColor: Colors.red,
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
              SnackBar(content: Text("Cleared $count archived content logs."), backgroundColor: Colors.green),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Error clearing history: $e"), backgroundColor: Colors.red),
            );
          }
        }
      },
      onCancel: () => Navigator.pop(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        ),
        title: const Text("Daily Content History", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(IconlyLight.delete, color: Colors.white),
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
          color: Colors.grey[50],
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30.r),
            topRight: Radius.circular(30.r),
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("daily_content")
              .orderBy("createdDate", descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: AppColors.primaryColor));
            }

            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(IconlyLight.bookmark, size: 50.r, color: Colors.grey[300]),
                    SizedBox(height: 10.h),
                    const Text("No content items found.", style: TextStyle(color: Colors.grey)),
                  ],
                ),
              );
            }

            return ListView.separated(
              itemCount: docs.length,
              separatorBuilder: (_, __) => SizedBox(height: 10.h),
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
                    ? createdDateStamp.toDate().toIso8601String().substring(0, 10)
                    : "N/A";

                return FutureBuilder<int>(
                  future: _getAttendanceCount(eventId),
                  builder: (context, countSnap) {
                    final attendanceCount = countSnap.data ?? 0;

                    return Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
                      child: Padding(
                        padding: EdgeInsets.all(12.r),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  createdDateStr,
                                  style: TextStyle(fontSize: 12.sp, color: Colors.grey[600], fontWeight: FontWeight.bold),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? Colors.green[50]
                                        : isArchived
                                            ? Colors.grey[200]
                                            : Colors.blue[50],
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Text(
                                    isActive
                                        ? "Active"
                                        : isArchived
                                            ? "Archived"
                                            : "Inactive",
                                    style: TextStyle(
                                      color: isActive
                                          ? Colors.green[700]
                                          : isArchived
                                              ? Colors.grey[700]
                                              : Colors.blue[700],
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
                              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                            SizedBox(height: 8.h),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(IconlyLight.user, size: 16.r, color: Colors.grey),
                                    SizedBox(width: 4.w),
                                    Text(
                                      "By: ${createdBy.length > 8 ? createdBy.substring(0, 8) : createdBy}",
                                      style: TextStyle(fontSize: 12.sp, color: Colors.grey[700]),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Icon(IconlyLight.activity, size: 16.r, color: Colors.green),
                                    SizedBox(width: 4.w),
                                    Text(
                                      "Attendance: $attendanceCount",
                                      style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: Colors.green[700]),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
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
