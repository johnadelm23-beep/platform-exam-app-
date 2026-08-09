import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';
import 'package:platformexamapp/core/theme/app_page_route.dart';
import 'package:platformexamapp/core/widgets/app_image_viewer.dart';
import 'package:platformexamapp/core/widgets/empty_state.dart';
import 'package:platformexamapp/core/widgets/glass_card.dart';
import 'package:platformexamapp/core/widgets/loading_state.dart';
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("couldnt_open".tr(args: [link]))),
        );
      }
    }
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

    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: pageBg,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios, color: textColor, size: 20.r),
        ),
        title: Text(
          "todays_material".tr(),
          style: GoogleFonts.cairo(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        margin: EdgeInsets.only(top: 8.h),
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
              .collection("events")
              .where("isActive", isEqualTo: true)
              .limit(1)
              .snapshots(),
          builder: (context, eventSnapshot) {
            if (eventSnapshot.connectionState == ConnectionState.waiting) {
              return const LoadingState();
            }

            final eventDocs = eventSnapshot.data?.docs ?? [];
            if (eventDocs.isEmpty) {
              return _buildNoActiveEventView(context);
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
                  return const LoadingState();
                }

                final hasAttended = attendanceSnapshot.data?.exists ?? false;

                if (!hasAttended) {
                  return _buildLockedView(context, eventTitle, eventDesc);
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
                      return const LoadingState();
                    }

                    final contentDocs = contentSnapshot.data?.docs ?? [];
                    if (contentDocs.isEmpty) {
                      return _buildEmptyContentView(context, eventTitle);
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

  Widget _buildNoActiveEventView(BuildContext context) {
    return EmptyState(
      title: "no_active_meeting".tr(),
      subtitle: "no_active_meeting_desc".tr(),
      hugeIcon: HugeIcons.strokeRoundedActivity01,
    );
  }

  Widget _buildLockedView(
    BuildContext context,
    String title,
    String description,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextMain : AppColors.lightTextMain;

    return Padding(
      padding: EdgeInsets.all(24.r),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color: AppColors.heartRed.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedLock,
              size: 60.r,
              color: AppColors.heartRed,
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            "lesson_materials_locked".tr(),
            style: GoogleFonts.cairo(
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          SizedBox(height: 8.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: AppColors.softGold.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.softGold.withOpacity(0.3)),
            ),
            child: Text(
              title,
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold,
                color: AppColors.softGold,
                fontSize: 14.sp,
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            "lesson_materials_locked_desc".tr(),
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 14.sp,
              color: isDark
                  ? AppColors.darkTextMuted
                  : AppColors.lightTextMuted,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyContentView(BuildContext context, String eventTitle) {
    return EmptyState(
      title: "no_materials_added_yet".tr(),
      subtitle: "no_materials_added_yet_desc".tr(args: [eventTitle]),
      hugeIcon: HugeIcons.strokeRoundedFileBookmark,
    );
  }

  Widget _buildUnlockedContentView(
    BuildContext context,
    String eventTitle,
    String docId,
    Map<String, dynamic> data,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextMain : AppColors.lightTextMain;
    final mutedColor = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;

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
      padding: EdgeInsets.all(20.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Access Unlocked Info Card
          GlassCard(
            padding: EdgeInsets.all(16.r),
            borderRadius: 20.r,
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    color: AppColors.successGreen.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_open_rounded,
                    color: AppColors.successGreen,
                    size: 24.r,
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "access_unlocked".tr(),
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          fontSize: 15.sp,
                          color: AppColors.successGreen,
                        ),
                      ),
                      Text(
                        "access_unlocked_desc".tr(),
                        style: GoogleFonts.cairo(
                          fontSize: 12.sp,
                          color: mutedColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),

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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20.r),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    coverImage.toString(),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            SizedBox(height: 16.h),
          ],

          Text(
            title,
            style: GoogleFonts.cairo(
              fontSize: 22.sp,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            SizedBox(height: 4.h),
            Text(
              subtitle,
              style: GoogleFonts.cairo(
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                color: mutedColor,
              ),
            ),
          ],
          if (desc.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Text(
              desc,
              style: GoogleFonts.cairo(
                fontSize: 14.sp,
                color: mutedColor,
                height: 1.6,
              ),
            ),
          ],
          SizedBox(height: 16.h),
          Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          SizedBox(height: 16.h),

          // Bible Reading
          if (bibleReading.isNotEmpty) ...[
            _buildSectionHeader(
              context,
              "bible_reading".tr(),
              HugeIcons.strokeRoundedFile01,
            ),
            GlassCard(
              padding: EdgeInsets.all(14.r),
              borderRadius: 16.r,
              child: Text(
                bibleReading,
                style: GoogleFonts.cairo(
                  fontSize: 14.sp,
                  height: 1.6,
                  color: textColor,
                ),
              ),
            ),
            SizedBox(height: 16.h),
          ],

          // Memory Verse
          if (verse.isNotEmpty) ...[
            _buildSectionHeader(
              context,
              "memory_verse".tr(),
              HugeIcons.strokeRoundedFavourite,
            ),
            GlassCard(
              padding: EdgeInsets.all(14.r),
              borderRadius: 16.r,
              child: Text(
                verse,
                style: GoogleFonts.cairo(
                  fontSize: 15.sp,
                  fontStyle: FontStyle.italic,
                  height: 1.6,
                  color: AppColors.softGold,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 16.h),
          ],

          // Homework
          if (homework.isNotEmpty) ...[
            _buildSectionHeader(
              context,
              "homework_task".tr(),
              HugeIcons.strokeRoundedFileBookmark,
            ),
            GlassCard(
              padding: EdgeInsets.all(14.r),
              borderRadius: 16.r,
              child: Text(
                homework,
                style: GoogleFonts.cairo(
                  fontSize: 14.sp,
                  height: 1.6,
                  color: textColor,
                ),
              ),
            ),
            SizedBox(height: 16.h),
          ],

          // Notes
          if (notes.isNotEmpty) ...[
            _buildSectionHeader(
              context,
              "teacher_notes".tr(),
              HugeIcons.strokeRoundedEdit01,
            ),
            GlassCard(
              padding: EdgeInsets.all(14.r),
              borderRadius: 16.r,
              child: Text(
                notes,
                style: GoogleFonts.cairo(
                  fontSize: 14.sp,
                  height: 1.6,
                  color: textColor,
                ),
              ),
            ),
            SizedBox(height: 16.h),
          ],

          // Video Links
          if (videoLinks.isNotEmpty) ...[
            _buildSectionHeader(
              context,
              "videos".tr(),
              HugeIcons.strokeRoundedVideo01,
            ),
            ...videoLinks.map((vid) {
              return Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: GlassCard(
                  padding: EdgeInsets.all(12.r),
                  borderRadius: 16.r,
                  child: Material(
                    color: Colors.transparent,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedVideo01,
                          color: Colors.purple.shade300,
                          size: 20.r,
                        ),
                      ),
                      title: Text(
                        vid.length > 30 ? "${vid.substring(0, 30)}..." : vid,
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.sp,
                          color: textColor,
                        ),
                      ),
                      trailing: Icon(
                        Icons.open_in_new,
                        color: AppColors.softGold,
                        size: 18.r,
                      ),
                      onTap: () async {
                        await _openExternalLink(context, vid);
                      },
                    ),
                  ),
                ),
              );
            }),
            SizedBox(height: 16.h),
          ],

          // External links
          if (externalLinks.isNotEmpty) ...[
            _buildSectionHeader(
              context,
              "external_links".tr(),
              HugeIcons.strokeRoundedGrid,
            ),
            ...externalLinks.map((link) {
              return Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: GlassCard(
                  padding: EdgeInsets.all(12.r),
                  borderRadius: 16.r,
                  child: Material(
                    color: Colors.transparent,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: AppColors.softGold.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedComment01,
                          color: AppColors.softGold,
                          size: 20.r,
                        ),
                      ),
                      title: Text(
                        link.length > 35 ? "${link.substring(0, 35)}..." : link,
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.sp,
                          color: textColor,
                        ),
                      ),
                      trailing: Icon(
                        Icons.open_in_new,
                        color: AppColors.softGold,
                        size: 18.r,
                      ),
                      onTap: () async {
                        debugPrint("Opening: $link");
                        await _openExternalLink(context, link);
                      },
                    ),
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, dynamic icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextMain : AppColors.lightTextMain;

    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        children: [
          HugeIcon(icon: icon, color: AppColors.softGold, size: 20.r),
          SizedBox(width: 8.w),
          Text(
            title,
            style: GoogleFonts.cairo(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
