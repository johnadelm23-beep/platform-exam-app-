import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconly/iconly.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';
import 'package:platformexamapp/core/theme/app_page_route.dart';
import 'package:platformexamapp/core/widgets/app_image_viewer.dart';
import 'package:url_launcher/url_launcher.dart';

class DailyContentScreen extends StatelessWidget {
  const DailyContentScreen({super.key});
  Future<void> _openExternalLink(BuildContext context, String link) async {
    try {
      String url = link.trim();

      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        url = 'https://$url';
      }

      final Uri uri = Uri.parse(url);

      final success = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!success) {
        throw Exception("Cannot open $url");
      }
    } catch (e) {
      debugPrint("Launch Error: $e");

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("couldnt_open".tr(args: [link]))));
      }
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
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        ),
        title: Text(
          "todays_material".tr(),
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Container(
        margin: EdgeInsets.only(top: 10.h),
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
              .collection("events")
              .where("isActive", isEqualTo: true)
              .limit(1)
              .snapshots(),
          builder: (context, eventSnapshot) {
            if (eventSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primaryColor),
              );
            }

            final eventDocs = eventSnapshot.data?.docs ?? [];
            if (eventDocs.isEmpty) {
              return _buildNoActiveEventView();
            }

            final eventDoc = eventDocs.first;
            final eventId = eventDoc.id;
            final eventData = eventDoc.data() as Map<String, dynamic>;
            final eventTitle = eventData["title"] ?? "Today's Event";
            final eventDesc = eventData["description"] ?? "";

            // Check if user is present for this event
            final attendanceDocId = "${eventId}_$uid";
            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("attendance")
                  .doc(attendanceDocId)
                  .snapshots(),
              builder: (context, attendanceSnapshot) {
                if (attendanceSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryColor,
                    ),
                  );
                }

                final hasAttended = attendanceSnapshot.data?.exists ?? false;

                if (!hasAttended) {
                  return _buildLockedView(eventTitle, eventDesc);
                }

                // If attended, load daily content document matching eventId that is active
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("daily_content")
                      .where("eventId", isEqualTo: eventId)
                      .where("isActive", isEqualTo: true)
                      .limit(1)
                      .snapshots(),
                  builder: (context, contentSnapshot) {
                    if (contentSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryColor,
                        ),
                      );
                    }

                    final contentDocs = contentSnapshot.data?.docs ?? [];
                    if (contentDocs.isEmpty) {
                      return _buildEmptyContentView(eventTitle);
                    }

                    final contentData =
                        contentDocs.first.data() as Map<String, dynamic>;
                    return _buildUnlockedContentView(
                      context,
                      eventTitle,
                      contentDocs.first.id,
                      contentData,
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

  Widget _buildNoActiveEventView() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(IconlyLight.activity, size: 60.r, color: Colors.grey[400]),
            SizedBox(height: 16.h),
            Text(
              "no_active_meeting".tr(),
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              "no_active_meeting_desc".tr(),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLockedView(String title, String description) {
    return Padding(
      padding: EdgeInsets.all(24.r),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color: Colors.red[50],
              shape: BoxShape.circle,
            ),
            child: Icon(IconlyBold.lock, size: 70.r, color: Colors.red[400]),
          ),
          SizedBox(height: 24.h),
          Text(
            "lesson_materials_locked".tr(),
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryColor,
                fontSize: 14.sp,
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            "lesson_materials_locked_desc".tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyContentView(String eventTitle) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(IconlyLight.bookmark, size: 50.r, color: Colors.orange[300]),
            SizedBox(height: 15.h),
            Text(
              "no_materials_added_yet".tr(),
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.h),
            Text(
              "no_materials_added_yet_desc".tr(args: [eventTitle]),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnlockedContentView(
    BuildContext context,
    String eventTitle,
    String docId,
    Map<String, dynamic> data,
  ) {
    final title = data["title"] ?? eventTitle;
    final subtitle = data["subtitle"] ?? "";
    final desc = data["description"] ?? "";
    final bibleReading = data["bibleReading"] ?? "";
    final verse = data["verse"] ?? "";
    final homework = data["homework"] ?? "";
    final notes = data["notes"] ?? "";
    final coverImage =
        data["coverImage"] ??
        (List<String>.from(data["images"] ?? []).isNotEmpty
            ? List<String>.from(data["images"] ?? []).first
            : null);
    final videoLinks = List<String>.from(data["videoLinks"] ?? []);
    final externalLinks = List<String>.from(data["externalLinks"] ?? []);

    final heroTag = "cover_image_hero_$docId";

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Access Unlocked Info Card
          Card(
            color: Colors.green[50],
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Padding(
              padding: EdgeInsets.all(16.r),
              child: Row(
                children: [
                  Icon(Icons.lock_open, color: Colors.green[700], size: 28.r),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "access_unlocked".tr(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.sp,
                            color: Colors.green[800],
                          ),
                        ),
                        Text(
                          "access_unlocked_desc".tr(),
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 15.h),

          // Cover Image View
          if (coverImage != null && coverImage.toString().isNotEmpty) ...[
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  AppPageRoute(
                    child: AppImageViewer(
                      imageUrl: coverImage.toString(),
                      heroTag: heroTag,
                    ),
                  ),
                );
              },
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(coverImage.toString(), fit: BoxFit.cover),
              ),
            ),
            SizedBox(height: 15.h),
          ],

          Text(
            title,
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            SizedBox(height: 4.h),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ],
          if (desc.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Text(
              desc,
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
            ),
          ],
          const Divider(height: 30),

          // Bible Reading
          if (bibleReading.isNotEmpty) ...[
            _buildSectionHeader("bible_reading".tr(), IconlyLight.document),
            Container(
              padding: EdgeInsets.all(12.r),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Text(
                bibleReading,
                style: TextStyle(
                  fontSize: 15.sp,
                  height: 1.5,
                  color: Colors.black87,
                ),
              ),
            ),
            SizedBox(height: 20.h),
          ],

          // Memory Verse
          if (verse.isNotEmpty) ...[
            _buildSectionHeader("memory_verse".tr(), IconlyLight.heart),
            Container(
              padding: EdgeInsets.all(12.r),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Text(
                verse,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontStyle: FontStyle.italic,
                  height: 1.5,
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 20.h),
          ],

          // Homework
          if (homework.isNotEmpty) ...[
            _buildSectionHeader("homework_task".tr(), IconlyLight.bookmark),
            Container(
              padding: EdgeInsets.all(12.r),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Text(
                homework,
                style: TextStyle(
                  fontSize: 15.sp,
                  height: 1.5,
                  color: Colors.black87,
                ),
              ),
            ),
            SizedBox(height: 20.h),
          ],

          // Notes
          if (notes.isNotEmpty) ...[
            _buildSectionHeader("teacher_notes".tr(), IconlyLight.edit),
            Container(
              padding: EdgeInsets.all(12.r),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: Text(
                notes,
                style: TextStyle(
                  fontSize: 14.sp,
                  height: 1.5,
                  color: Colors.black87,
                ),
              ),
            ),
            SizedBox(height: 20.h),
          ],

          // Video Links
          if (videoLinks.isNotEmpty) ...[
            _buildSectionHeader("videos".tr(), IconlyLight.video),
            ...videoLinks.map((vid) {
              return Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  side: BorderSide(color: Colors.grey[200]!),
                ),
                child: ListTile(
                  leading: const Icon(IconlyLight.video, color: Colors.purple),
                  title: Text(
                    vid.length > 30 ? "${vid.substring(0, 30)}..." : vid,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.sp,
                    ),
                  ),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () {
                    // Open link action
                  },
                ),
              );
            }),
            SizedBox(height: 20.h),
          ],

          // External links
          if (externalLinks.isNotEmpty) ...[
            _buildSectionHeader("external_links".tr(), IconlyLight.category),
            ...externalLinks.map((link) {
              return Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  side: BorderSide(color: Colors.grey[200]!),
                ),
                child: ListTile(
                  leading: const Icon(
                    IconlyLight.message,
                    color: AppColors.primaryColor,
                  ),
                  title: Text(
                    link.length > 35 ? "${link.substring(0, 35)}..." : link,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.sp,
                    ),
                  ),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () async {
                    debugPrint("Opening: $link");
                    await _openExternalLink(context, link);
                  },
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryColor, size: 20.r),
          SizedBox(width: 8.w),
          Text(
            title,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }
}
