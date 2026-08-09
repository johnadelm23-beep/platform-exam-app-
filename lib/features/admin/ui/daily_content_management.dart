import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http_parser/http_parser.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:mime/mime.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';
import 'package:platformexamapp/core/widgets/app_dialog.dart';

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
  final _videoController =
      TextEditingController(); // Comma-separated video links
  final _externalController =
      TextEditingController(); // Comma-separated external links

  String _searchQuery = "";
  String _filterType = "all"; // all, active, archived
  final String _sortBy = "newest"; // newest
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
          backgroundColor: Colors.red,
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
          backgroundColor: Colors.red,
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
          backgroundColor: Colors.red,
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
          backgroundColor: Colors.red,
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
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _deleteContent(String docId) {
    AppDialog.show(
      context: context,
      icon: Icons.delete_forever,
      iconColor: Colors.red,
      title: "Delete Content",
      description:
          "This action cannot be undone. Are you sure you want to delete this content item?",
      confirmText: "Delete",
      confirmButtonColor: Colors.red,
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
              backgroundColor: Colors.red,
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

            return Container(
              padding: EdgeInsets.only(
                top: 20.r,
                left: 16.r,
                right: 16.r,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20.r,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30.r),
                  topRight: Radius.circular(30.r),
                ),
              ),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40.w,
                          height: 4.h,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                        ),
                      ),
                      SizedBox(height: 15.h),
                      Text(
                        editDocId == null
                            ? "Create Daily Content"
                            : "Edit Daily Content",
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor,
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
                            decoration: InputDecoration(
                              labelText: "Select Event",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                            items: events.map((e) {
                              final data = e.data() as Map<String, dynamic>;
                              return DropdownMenuItem<String>(
                                value: e.id,
                                child: Text(data["title"] ?? "Event"),
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
                        decoration: InputDecoration(
                          labelText: "Content Title",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
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
                        decoration: InputDecoration(
                          labelText: "Subtitle",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      TextFormField(
                        controller: _descController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: "Description",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      TextFormField(
                        controller: _bibleController,
                        decoration: InputDecoration(
                          labelText: "Bible Reading (Text)",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      TextFormField(
                        controller: _verseController,
                        decoration: InputDecoration(
                          labelText: "Memory Verse",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      TextFormField(
                        controller: _homeworkController,
                        decoration: InputDecoration(
                          labelText: "Homework Task",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      TextFormField(
                        controller: _notesController,
                        decoration: InputDecoration(
                          labelText: "Notes",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                      ),
                      SizedBox(height: 20.h),

                      // Cover Image Section
                      Text(
                        "Cover Image",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15.sp,
                          color: Colors.grey[700],
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
                                  color: Colors.grey[200],
                                  child: const Icon(
                                    Icons.broken_image,
                                    color: Colors.grey,
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
                                      backgroundColor: Colors.blue.withOpacity(
                                        0.9,
                                      ),
                                      child: Icon(
                                        Icons.edit,
                                        size: 18.r,
                                        color: Colors.white,
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
                                      backgroundColor: Colors.red.withOpacity(
                                        0.9,
                                      ),
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
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(),
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
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: pickCoverImage,
                                icon: const Icon(Icons.add_photo_alternate),
                                label: const Text(
                                  "Choose Cover Image from Phone",
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: 12.h),
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
                        decoration: InputDecoration(
                          labelText: "Video URLs (comma-separated)",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      TextFormField(
                        controller: _externalController,
                        decoration: InputDecoration(
                          labelText: "External Web Links (comma-separated)",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
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
                            backgroundColor: AppColors.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          child: Text(
                            editDocId == null
                                ? "Create Content"
                                : "Update Content",
                            style: TextStyle(
                              fontWeight: .bold,
                              fontSize: 24.sp,
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
    final previewCover =
        data["coverImage"] ??
        (List<String>.from(data["images"] ?? []).isNotEmpty
            ? List<String>.from(data["images"] ?? []).first
            : null);

    AppDialog.show(
      context: context,
      iconWidget: HugeIcon(
        icon: HugeIcons.strokeRoundedFileBookmark,
        color: AppColors.primaryColor,
        size: 36.r,
      ),
      iconColor: AppColors.primaryColor,
      title: data["title"] ?? "Preview Content",
      description: data["subtitle"] ?? "No subtitle provided",
      confirmText: "Close",
      confirmButtonColor: Colors.green,
      onConfirm: () => Navigator.pop(context),
      customContent: Flexible(
        child: SingleChildScrollView(
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
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.broken_image,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
              if (data["description"] != null)
                Text(
                  data["description"],
                  style: TextStyle(fontSize: 14.sp, color: Colors.black87),
                ),
              const Divider(),
              if (data["bibleReading"] != null &&
                  data["bibleReading"].toString().isNotEmpty) ...[
                const Text(
                  "Bible Reading:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(data["bibleReading"]),
                SizedBox(height: 10.h),
              ],
              if (data["verse"] != null &&
                  data["verse"].toString().isNotEmpty) ...[
                const Text(
                  "Verse:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(data["verse"]),
                SizedBox(height: 10.h),
              ],
              if (data["homework"] != null &&
                  data["homework"].toString().isNotEmpty) ...[
                const Text(
                  "Homework:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(data["homework"]),
              ],
            ],
          ),
        ),
      ),
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
        title: const Text(
          "Daily Content Manager",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditBottomSheet(),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primaryColor,
        child: const Icon(Icons.add),
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
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Search content...",
                      prefixIcon: HugeIcon(
                        icon: HugeIcons.strokeRoundedSearch01,
                        size: 20.r,
                      ),
                      fillColor: Colors.white,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15.r),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val.trim().toLowerCase();
                      });
                    },
                  ),
                ),
                SizedBox(width: 8.w),
                DropdownButton<String>(
                  value: _filterType,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All')),
                    DropdownMenuItem(value: 'active', child: Text('Active')),
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
              ],
            ),
            SizedBox(height: 10.h),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("daily_content")
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryColor,
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
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedFileBookmark,
                            size: 50.r,
                            color: Colors.grey[300],
                          ),
                          SizedBox(height: 10.h),
                          const Text(
                            "No content items found.",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: filteredDocs.length,
                    separatorBuilder: (_, __) => SizedBox(height: 10.h),
                    itemBuilder: (context, index) {
                      final doc = filteredDocs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final title = data["title"] ?? "";
                      final subtitle = data["subtitle"] ?? "";
                      final isActive = data["isActive"] ?? false;
                      final isArchived = data["isArchived"] ?? false;

                      return Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.r),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: ListTile(
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (isActive)
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 6.w,
                                      vertical: 2.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green[100],
                                      borderRadius: BorderRadius.circular(5.r),
                                    ),
                                    child: Text(
                                      "Active",
                                      style: TextStyle(
                                        fontSize: 10.sp,
                                        color: Colors.green[800],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                if (isArchived)
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 6.w,
                                      vertical: 2.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(5.r),
                                    ),
                                    child: Text(
                                      "Archived",
                                      style: TextStyle(
                                        fontSize: 10.sp,
                                        color: Colors.grey[700],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Text(
                              subtitle.isNotEmpty
                                  ? subtitle
                                  : "No subtitle provided",
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const HugeIcon(
                                    icon: HugeIcons.strokeRoundedEye,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () => _showPreviewDialog(data),
                                ),
                                PopupMenuButton<String>(
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
                                    const PopupMenuItem(
                                      value: "edit",
                                      child: Text("Edit"),
                                    ),
                                    const PopupMenuItem(
                                      value: "duplicate",
                                      child: Text("Duplicate"),
                                    ),
                                    if (!isActive && !isArchived)
                                      const PopupMenuItem(
                                        value: "activate",
                                        child: Text("Activate"),
                                      ),
                                    PopupMenuItem(
                                      value: "archive",
                                      child: Text(
                                        isArchived ? "Restore" : "Archive",
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: "delete",
                                      child: Text(
                                        "Delete",
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
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
