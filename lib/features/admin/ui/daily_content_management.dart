import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http_parser/http_parser.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:mime/mime.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';
import 'package:platformexamapp/core/widgets/app_dialog.dart';
import 'package:platformexamapp/core/widgets/empty_state.dart';
import 'package:platformexamapp/core/widgets/glass_card.dart';

class DailyContentManagementScreen extends StatefulWidget {
  const DailyContentManagementScreen({super.key});

  @override
  State<DailyContentManagementScreen> createState() =>
      _DailyContentManagementScreenState();
}

class _DailyContentManagementScreenState
    extends State<DailyContentManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _descController = TextEditingController();
  final _bibleController = TextEditingController();
  final _verseController = TextEditingController();
  final _homeworkController = TextEditingController();
  final _notesController = TextEditingController();
  final _videoController = TextEditingController();
  final _externalController = TextEditingController();

  String _searchQuery = "";
  String _filterType = "all"; // all, active, archived
  final String _sortBy = "newest";
  String? _selectedEventId;

  String? _coverImageUrl;
  bool _isUploading = false;
  String? _uploadError;

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _descController.dispose();
    _bibleController.dispose();
    _verseController.dispose();
    _homeworkController.dispose();
    _notesController.dispose();
    _videoController.dispose();
    _externalController.dispose();
    super.dispose();
  }

  void _clearControllers() {
    _titleController.clear();
    _subtitleController.clear();
    _descController.clear();
    _bibleController.clear();
    _verseController.clear();
    _homeworkController.clear();
    _notesController.clear();
    _videoController.clear();
    _externalController.clear();
    _selectedEventId = null;
    _coverImageUrl = null;
    _uploadError = null;
  }

  void _populateControllers(Map<String, dynamic> data) {
    _titleController.text = data["title"] ?? "";
    _subtitleController.text = data["subtitle"] ?? "";
    _descController.text = data["description"] ?? "";
    _bibleController.text = data["bibleReading"] ?? "";
    _verseController.text = data["verse"] ?? "";
    _homeworkController.text = data["homework"] ?? "";
    _notesController.text = data["notes"] ?? "";
    _videoController.text = List<String>.from(
      data["videoLinks"] ?? [],
    ).join(", ");
    _externalController.text = List<String>.from(
      data["externalLinks"] ?? [],
    ).join(", ");
    _selectedEventId = data["eventId"];
    _coverImageUrl =
        data["coverImage"] ??
        (List<String>.from(data["images"] ?? []).isNotEmpty
            ? List<String>.from(data["images"] ?? []).first
            : null);
    _uploadError = null;
  }

  Future<String?> _pickAndUploadFile(String folder) async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);

      if (result == null || result.files.single.path == null) {
        return null;
      }

      final file = File(result.files.single.path!);

      final mimeType = lookupMimeType(file.path) ?? "image/jpeg";

      final formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(
          file.path,
          contentType: MediaType.parse(mimeType),
        ),
        "upload_preset": "testing",
        "folder": folder,
      });

      final response = await Dio().post(
        "https://api.cloudinary.com/v1_1/no25n6db/image/upload",
        data: formData,
      );

      if (response.statusCode == 200) {
        return response.data["secure_url"];
      }

      return null;
    } catch (e) {
      setState(() {
        _uploadError = e.toString();
      });
      return null;
    }
  }

  Future<void> _saveContent({String? editDocId}) async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    final userDoc = await FirebaseFirestore.instance
        .collection("users")
        .doc(currentUser.uid)
        .get();
    if (userDoc.data()?["isAdmin"] != true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Permission denied: Main Admin only."),
          backgroundColor: AppColors.heartRed,
        ),
      );
      return;
    }

    final String adminId = currentUser.uid;
    final data = {
      "eventId": _selectedEventId ?? "",
      "title": _titleController.text.trim(),
      "subtitle": _subtitleController.text.trim(),
      "description": _descController.text.trim(),
      "bibleReading": _bibleController.text.trim(),
      "verse": _verseController.text.trim(),
      "homework": _homeworkController.text.trim(),
      "notes": _notesController.text.trim(),
      "coverImage": _coverImageUrl ?? "",
      "images": _coverImageUrl != null && _coverImageUrl!.isNotEmpty
          ? [_coverImageUrl!]
          : [],
      "pdfFiles": [],
      "audioFiles": [],
      "videoLinks": _videoController.text
          .split(",")
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList(),
      "externalLinks": _externalController.text
          .split(",")
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList(),
      "attachments": [],
      "createdBy": adminId,
      "updatedDate": FieldValue.serverTimestamp(),
      "isActive": false,
      "isArchived": false,
    };

    try {
      if (editDocId == null) {
        final docRef = FirebaseFirestore.instance
            .collection("daily_content")
            .doc();
        data["id"] = docRef.id;
        data["createdDate"] = FieldValue.serverTimestamp();
        await docRef.set(data);
      } else {
        await FirebaseFirestore.instance
            .collection("daily_content")
            .doc(editDocId)
            .update(data);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              editDocId == null
                  ? "Content created successfully!"
                  : "Content updated successfully!",
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error saving content: $e"),
          backgroundColor: AppColors.heartRed,
        ),
      );
    }
  }

  Future<void> _activateContent(String docId) async {
    try {
      final activeContent = await FirebaseFirestore.instance
          .collection("daily_content")
          .where("isActive", isEqualTo: true)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (var doc in activeContent.docs) {
        batch.update(doc.reference, {"isActive": false});
      }
      batch.update(
        FirebaseFirestore.instance.collection("daily_content").doc(docId),
        {"isActive": true},
      );
      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Content activated successfully!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error activating content: $e"),
          backgroundColor: AppColors.heartRed,
        ),
      );
    }
  }

  Future<void> _archiveContent(String docId, bool currentStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection("daily_content")
          .doc(docId)
          .update({"isArchived": !currentStatus, "isActive": false});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            !currentStatus
                ? "Content archived successfully!"
                : "Content restored successfully!",
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error archiving content: $e"),
          backgroundColor: AppColors.heartRed,
        ),
      );
    }
  }

  Future<void> _duplicateContent(Map<String, dynamic> data) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection("daily_content")
          .doc();
      final clonedData = Map<String, dynamic>.from(data);
      clonedData["id"] = docRef.id;
      clonedData["title"] = "${data['title']} (Copy)";
      clonedData["isActive"] = false;
      clonedData["isArchived"] = false;
      clonedData["createdDate"] = FieldValue.serverTimestamp();
      clonedData["updatedDate"] = FieldValue.serverTimestamp();

      await docRef.set(clonedData);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Content duplicated successfully!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error duplicating content: $e"),
          backgroundColor: AppColors.heartRed,
        ),
      );
    }
  }

  void _deleteContent(String docId) {
    AppDialog.show(
      context: context,
      icon: Icons.delete_forever,
      iconColor: AppColors.heartRed,
      title: "Delete Content",
      description:
          "This action cannot be undone. Are you sure you want to delete this content item?",
      confirmText: "Delete",
      confirmButtonColor: AppColors.heartRed,
      cancelText: "Cancel",
      onConfirm: () async {
        Navigator.pop(context); // Close dialog
        try {
          await FirebaseFirestore.instance
              .collection("daily_content")
              .doc(docId)
              .delete();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Content deleted successfully!"),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error deleting content: $e"),
              backgroundColor: AppColors.heartRed,
            ),
          );
        }
      },
      onCancel: () => Navigator.pop(context),
    );
  }

  void _showAddEditBottomSheet({
    String? editDocId,
    Map<String, dynamic>? initialData,
  }) {
    if (initialData != null) {
      _populateControllers(initialData);
    } else {
      _clearControllers();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : Colors.white;
    final textColor = isDark ? AppColors.darkTextMain : AppColors.lightTextMain;
    final mutedColor = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final inputBg = isDark
        ? AppColors.darkGlassSurface
        : AppColors.lightGlassSurface;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> pickCoverImage() async {
              setModalState(() {
                _isUploading = true;
                _uploadError = null;
              });

              final url = await _pickAndUploadFile("daily_content/images");

              if (url != null) {
                _coverImageUrl = url;
              }

              setModalState(() {
                _isUploading = false;
                if (url != null) {
                  _coverImageUrl = url;
                }
              });
            }

            InputDecoration buildInputDecoration(
              String labelText, {
              Widget? prefixIcon,
            }) {
              return InputDecoration(
                labelText: labelText,
                labelStyle: GoogleFonts.cairo(
                  color: mutedColor,
                  fontSize: 13.sp,
                ),
                prefixIcon: prefixIcon,
                fillColor: inputBg,
                filled: true,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: const BorderSide(
                    color: AppColors.softGold,
                    width: 1.5,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: borderColor),
                ),
              );
            }

            return Container(
              padding: EdgeInsets.only(
                top: 20.r,
                left: 16.r,
                right: 16.r,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20.r,
              ),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30.r),
                  topRight: Radius.circular(30.r),
                ),
                border: Border.all(color: borderColor),
              ),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40.w,
                          height: 4.h,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkBorder
                                : Colors.grey[300],
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                        ),
                      ),
                      SizedBox(height: 15.h),
                      Text(
                        editDocId == null
                            ? "Create Daily Content"
                            : "Edit Daily Content",
                        style: GoogleFonts.cairo(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.softGold
                              : AppColors.primaryColor,
                        ),
                      ),
                      SizedBox(height: 15.h),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection("events")
                            .orderBy("createdAt", descending: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          final events = snapshot.data?.docs ?? [];
                          return DropdownButtonFormField<String>(
                            value: _selectedEventId,
                            dropdownColor: surfaceColor,
                            style: GoogleFonts.cairo(
                              color: textColor,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: buildInputDecoration(
                              "Select Event",
                              prefixIcon: HugeIcon(
                                icon: HugeIcons.strokeRoundedCalendar01,
                                size: 20.r,
                                color: AppColors.softGold,
                              ),
                            ),
                            items: events.map((e) {
                              final data = e.data() as Map<String, dynamic>;
                              return DropdownMenuItem<String>(
                                value: e.id,
                                child: Text(
                                  data["title"] ?? "Event",
                                  style: GoogleFonts.cairo(color: textColor),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setModalState(() {
                                _selectedEventId = val;
                              });
                            },
                            validator: (value) => value == null
                                ? "Event selection is required"
                                : null,
                          );
                        },
                      ),
                      SizedBox(height: 12.h),
                      TextFormField(
                        controller: _titleController,
                        style: GoogleFonts.cairo(color: textColor),
                        decoration: buildInputDecoration(
                          "Content Title",
                          prefixIcon: HugeIcon(
                            icon: HugeIcons.strokeRoundedFile01,
                            size: 20.r,
                            color: AppColors.softGold,
                          ),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? "Title is required"
                            : null,
                      ),
                      SizedBox(height: 12.h),
                      TextFormField(
                        controller: _subtitleController,
                        style: GoogleFonts.cairo(color: textColor),
                        decoration: buildInputDecoration(
                          "Subtitle",
                          prefixIcon: HugeIcon(
                            icon: HugeIcons.strokeRoundedEdit01,
                            size: 20.r,
                            color: AppColors.softGold,
                          ),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      TextFormField(
                        controller: _descController,
                        maxLines: 3,
                        style: GoogleFonts.cairo(color: textColor),
                        decoration: buildInputDecoration("Description"),
                      ),
                      SizedBox(height: 12.h),
                      TextFormField(
                        controller: _bibleController,
                        style: GoogleFonts.cairo(color: textColor),
                        decoration: buildInputDecoration(
                          "Bible Reading (Text)",
                        ),
                      ),
                      SizedBox(height: 12.h),
                      TextFormField(
                        controller: _verseController,
                        style: GoogleFonts.cairo(color: textColor),
                        decoration: buildInputDecoration("Memory Verse"),
                      ),
                      SizedBox(height: 12.h),
                      TextFormField(
                        controller: _homeworkController,
                        style: GoogleFonts.cairo(color: textColor),
                        decoration: buildInputDecoration("Homework Task"),
                      ),
                      SizedBox(height: 12.h),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 2,
                        style: GoogleFonts.cairo(color: textColor),
                        decoration: buildInputDecoration("Notes"),
                      ),
                      SizedBox(height: 20.h),

                      // Cover Image Section
                      Text(
                        "Cover Image",
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                          color: mutedColor,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      if (_coverImageUrl != null && _coverImageUrl!.isNotEmpty)
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12.r),
                              child: Image.network(
                                _coverImageUrl!,
                                width: double.infinity,
                                height: 160.h,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: double.infinity,
                                  height: 160.h,
                                  color: inputBg,
                                  child: const Icon(
                                    Icons.broken_image,
                                    color: AppColors.softGold,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 10,
                              top: 10,
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: pickCoverImage,
                                    child: CircleAvatar(
                                      radius: 18.r,
                                      backgroundColor: AppColors.softGold,
                                      child: Icon(
                                        Icons.edit,
                                        size: 18.r,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  GestureDetector(
                                    onTap: () => setModalState(
                                      () => _coverImageUrl = null,
                                    ),
                                    child: CircleAvatar(
                                      radius: 18.r,
                                      backgroundColor: AppColors.heartRed,
                                      child: Icon(
                                        Icons.close,
                                        size: 18.r,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      else if (_isUploading)
                        Container(
                          width: double.infinity,
                          height: 100.h,
                          decoration: BoxDecoration(
                            color: inputBg,
                            border: Border.all(color: borderColor),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.softGold,
                            ),
                          ),
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_uploadError != null)
                              Padding(
                                padding: EdgeInsets.only(bottom: 8.h),
                                child: Text(
                                  "Upload failed: $_uploadError",
                                  style: GoogleFonts.cairo(
                                    color: AppColors.heartRed,
                                  ),
                                ),
                              ),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: pickCoverImage,
                                icon: const HugeIcon(
                                  icon: HugeIcons.strokeRoundedImage01,
                                  color: AppColors.softGold,
                                ),
                                label: Text(
                                  "Choose Cover Image from Phone",
                                  style: GoogleFonts.cairo(
                                    color: textColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: 12.h),
                                  side: BorderSide(color: borderColor),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      SizedBox(height: 20.h),

                      TextFormField(
                        controller: _videoController,
                        style: GoogleFonts.cairo(color: textColor),
                        decoration: buildInputDecoration(
                          "Video URLs (comma-separated)",
                          prefixIcon: HugeIcon(
                            icon: HugeIcons.strokeRoundedVideo01,
                            size: 20.r,
                            color: AppColors.softGold,
                          ),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      TextFormField(
                        controller: _externalController,
                        style: GoogleFonts.cairo(color: textColor),
                        decoration: buildInputDecoration(
                          "External Web Links (comma-separated)",
                          prefixIcon: HugeIcon(
                            icon: HugeIcons.strokeRoundedGrid,
                            size: 20.r,
                            color: AppColors.softGold,
                          ),
                        ),
                      ),
                      SizedBox(height: 20.h),

                      SizedBox(
                        width: double.infinity,
                        height: 48.h,
                        child: ElevatedButton(
                          onPressed: _isUploading
                              ? null
                              : () => _saveContent(editDocId: editDocId),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.softGold,
                            foregroundColor: Colors.black87,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          child: Text(
                            editDocId == null
                                ? "Create Content"
                                : "Update Content",
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold,
                              fontSize: 16.sp,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showPreviewDialog(Map<String, dynamic> data) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextMain : AppColors.lightTextMain;
    final inputBg = isDark
        ? AppColors.darkGlassSurface
        : AppColors.lightGlassSurface;

    final previewCover =
        data["coverImage"] ??
        (List<String>.from(data["images"] ?? []).isNotEmpty
            ? List<String>.from(data["images"] ?? []).first
            : null);

    AppDialog.show(
      context: context,
      iconWidget: HugeIcon(
        icon: HugeIcons.strokeRoundedFileBookmark,
        color: AppColors.softGold,
        size: 36.r,
      ),
      iconColor: AppColors.softGold,
      title: data["title"] ?? "Preview Content",
      description: data["subtitle"] ?? "No subtitle provided",
      confirmText: "Close",
      confirmButtonColor: AppColors.softGold,
      onConfirm: () => Navigator.pop(context),
      customContent: Flexible(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (previewCover != null && previewCover.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: Image.network(
                      previewCover,
                      width: double.infinity,
                      height: 120.h,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: double.infinity,
                        height: 120.h,
                        color: inputBg,
                        child: const Icon(
                          Icons.broken_image,
                          color: AppColors.softGold,
                        ),
                      ),
                    ),
                  ),
                ),
              if (data["description"] != null)
                Text(
                  data["description"],
                  style: GoogleFonts.cairo(fontSize: 14.sp, color: textColor),
                ),
              Divider(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
              if (data["bibleReading"] != null &&
                  data["bibleReading"].toString().isNotEmpty) ...[
                Text(
                  "Bible Reading:",
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    color: AppColors.softGold,
                  ),
                ),
                Text(
                  data["bibleReading"],
                  style: GoogleFonts.cairo(color: textColor),
                ),
                SizedBox(height: 10.h),
              ],
              if (data["verse"] != null &&
                  data["verse"].toString().isNotEmpty) ...[
                Text(
                  "Verse:",
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    color: AppColors.softGold,
                  ),
                ),
                Text(data["verse"], style: GoogleFonts.cairo(color: textColor)),
                SizedBox(height: 10.h),
              ],
              if (data["homework"] != null &&
                  data["homework"].toString().isNotEmpty) ...[
                Text(
                  "Homework:",
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    color: AppColors.softGold,
                  ),
                ),
                Text(
                  data["homework"],
                  style: GoogleFonts.cairo(color: textColor),
                ),
              ],
            ],
          ),
        ),
      ),
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
    final secondaryTextColor = isDark
        ? const Color(0xFFCBD5E1)
        : Colors.black87;
    final mutedColor = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final inputBg = isDark
        ? AppColors.darkGlassSurface
        : AppColors.lightGlassSurface;

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
          "Daily Content Manager",
          style: GoogleFonts.cairo(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditBottomSheet(),
        backgroundColor: AppColors.softGold,
        foregroundColor: Colors.black87,
        child: const Icon(Icons.add),
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
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    style: GoogleFonts.cairo(color: textColor, fontSize: 14.sp),
                    decoration: InputDecoration(
                      hintText: "Search content...",
                      hintStyle: GoogleFonts.cairo(
                        color: mutedColor,
                        fontSize: 13.sp,
                      ),
                      prefixIcon: HugeIcon(
                        icon: HugeIcons.strokeRoundedSearch01,
                        size: 20.r,
                        color: AppColors.softGold,
                      ),
                      fillColor: inputBg,
                      filled: true,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.r),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.r),
                        borderSide: const BorderSide(
                          color: AppColors.softGold,
                          width: 1.5,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.r),
                        borderSide: BorderSide(color: borderColor),
                      ),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val.trim().toLowerCase();
                      });
                    },
                  ),
                ),
                SizedBox(width: 10.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  decoration: BoxDecoration(
                    color: inputBg,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: borderColor),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _filterType,
                      dropdownColor: surfaceColor,
                      icon: HugeIcon(
                        icon: HugeIcons.strokeRoundedFilter,
                        size: 18.r,
                        color: AppColors.softGold,
                      ),
                      style: GoogleFonts.cairo(
                        color: textColor,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All')),
                        DropdownMenuItem(
                          value: 'active',
                          child: Text('Active'),
                        ),
                        DropdownMenuItem(
                          value: 'archived',
                          child: Text('Archived'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _filterType = val;
                          });
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("daily_content")
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.softGold,
                      ),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];

                  List<QueryDocumentSnapshot> filteredDocs = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final title = (data["title"] ?? "")
                        .toString()
                        .toLowerCase();
                    final desc = (data["description"] ?? "")
                        .toString()
                        .toLowerCase();
                    final isActive = data["isActive"] ?? false;
                    final isArchived = data["isArchived"] ?? false;

                    final matchesSearch =
                        title.contains(_searchQuery) ||
                        desc.contains(_searchQuery);

                    bool matchesFilter = true;
                    if (_filterType == "active") {
                      matchesFilter = isActive;
                    } else if (_filterType == "archived") {
                      matchesFilter = isArchived;
                    } else {
                      matchesFilter = !isArchived;
                    }

                    return matchesSearch && matchesFilter;
                  }).toList();

                  if (_sortBy == "newest") {
                    filteredDocs.sort((a, b) {
                      final aDate =
                          (a.data() as Map)['createdDate'] as Timestamp?;
                      final bDate =
                          (b.data() as Map)['createdDate'] as Timestamp?;
                      if (aDate == null) return 1;
                      if (bDate == null) return -1;
                      return bDate.compareTo(aDate);
                    });
                  }

                  if (filteredDocs.isEmpty) {
                    return EmptyState(
                      title: "No content items found.",
                      hugeIcon: HugeIcons.strokeRoundedFileBookmark,
                    );
                  }

                  return ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    itemCount: filteredDocs.length,
                    separatorBuilder: (_, __) => SizedBox(height: 12.h),
                    itemBuilder: (context, index) {
                      final doc = filteredDocs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final title = data["title"] ?? "";
                      final subtitle = data["subtitle"] ?? "";
                      final isActive = data["isActive"] ?? false;
                      final isArchived = data["isArchived"] ?? false;

                      return GlassCard(
                        padding: EdgeInsets.all(14.r),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    style: GoogleFonts.cairo(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                ),
                                if (isActive)
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8.w,
                                      vertical: 3.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(8.r),
                                      border: Border.all(
                                        color: Colors.green.withValues(
                                          alpha: 0.4,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      "Active",
                                      style: GoogleFonts.cairo(
                                        fontSize: 11.sp,
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                if (isArchived)
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8.w,
                                      vertical: 3.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(8.r),
                                      border: Border.all(
                                        color: Colors.grey.withValues(
                                          alpha: 0.4,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      "Archived",
                                      style: GoogleFonts.cairo(
                                        fontSize: 11.sp,
                                        color: mutedColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            if (subtitle.isNotEmpty) ...[
                              SizedBox(height: 4.h),
                              Text(
                                subtitle,
                                style: GoogleFonts.cairo(
                                  fontSize: 13.sp,
                                  color: secondaryTextColor,
                                ),
                              ),
                            ],
                            SizedBox(height: 10.h),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: const HugeIcon(
                                    icon: HugeIcons.strokeRoundedEye,
                                    color: AppColors.softGold,
                                  ),
                                  onPressed: () => _showPreviewDialog(data),
                                ),
                                PopupMenuButton<String>(
                                  color: surfaceColor,
                                  icon: Icon(
                                    Icons.more_vert_rounded,
                                    color: textColor,
                                    size: 20.r,
                                  ),
                                  onSelected: (action) {
                                    if (action == "edit") {
                                      _showAddEditBottomSheet(
                                        editDocId: doc.id,
                                        initialData: data,
                                      );
                                    } else if (action == "duplicate") {
                                      _duplicateContent(data);
                                    } else if (action == "activate") {
                                      _activateContent(doc.id);
                                    } else if (action == "archive") {
                                      _archiveContent(doc.id, isArchived);
                                    } else if (action == "delete") {
                                      _deleteContent(doc.id);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: "edit",
                                      child: Text(
                                        "Edit",
                                        style: GoogleFonts.cairo(
                                          color: textColor,
                                        ),
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: "duplicate",
                                      child: Text(
                                        "Duplicate",
                                        style: GoogleFonts.cairo(
                                          color: textColor,
                                        ),
                                      ),
                                    ),
                                    if (!isActive && !isArchived)
                                      PopupMenuItem(
                                        value: "activate",
                                        child: Text(
                                          "Activate",
                                          style: GoogleFonts.cairo(
                                            color: textColor,
                                          ),
                                        ),
                                      ),
                                    PopupMenuItem(
                                      value: "archive",
                                      child: Text(
                                        isArchived ? "Restore" : "Archive",
                                        style: GoogleFonts.cairo(
                                          color: textColor,
                                        ),
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: "delete",
                                      child: Text(
                                        "Delete",
                                        style: GoogleFonts.cairo(
                                          color: AppColors.heartRed,
                                        ),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
