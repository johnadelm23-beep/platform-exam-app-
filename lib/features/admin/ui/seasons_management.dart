import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';
import 'package:platformexamapp/core/widgets/empty_state.dart';
import 'package:platformexamapp/core/widgets/glass_card.dart';

class SeasonsManagementScreen extends StatefulWidget {
  const SeasonsManagementScreen({super.key});

  @override
  State<SeasonsManagementScreen> createState() =>
      _SeasonsManagementScreenState();
}

class _SeasonsManagementScreenState extends State<SeasonsManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 90));
  bool _isActive = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.softGold,
              onPrimary: Colors.black,
              surface: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              onSurface: isDark
                  ? AppColors.darkTextMain
                  : AppColors.lightTextMain,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _saveSeason({String? editId}) async {
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

    final name = _nameController.text.trim();
    final startStr =
        "${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}";
    final endStr =
        "${_endDate.year}-${_endDate.month.toString().padLeft(2, '0')}-${_endDate.day.toString().padLeft(2, '0')}";

    try {
      if (_isActive) {
        // Deactivate all active seasons first
        final activeSeasons = await FirebaseFirestore.instance
            .collection("seasons")
            .where("status", isEqualTo: "active")
            .get();
        final batch = FirebaseFirestore.instance.batch();
        for (var doc in activeSeasons.docs) {
          batch.update(doc.reference, {"status": "inactive"});
        }
        await batch.commit();
      }

      final Map<String, dynamic> data = {
        "name": name,
        "startDate": startStr,
        "endDate": endStr,
        "status": _isActive ? "active" : "inactive",
      };

      if (editId == null) {
        final docRef = FirebaseFirestore.instance.collection("seasons").doc();
        data["id"] = docRef.id;
        data["createdAt"] = FieldValue.serverTimestamp();
        await docRef.set(data);
      } else {
        await FirebaseFirestore.instance
            .collection("seasons")
            .doc(editId)
            .update(data);
      }

      _nameController.clear();
      setState(() {
        _isActive = false;
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              editId == null
                  ? "Season created successfully!"
                  : "Season updated successfully!",
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error saving season: $e"),
          backgroundColor: AppColors.heartRed,
        ),
      );
    }
  }

  Future<void> _toggleSeasonActive(String seasonId, bool currentActive) async {
    try {
      if (currentActive) {
        // Toggle off, set to inactive
        await FirebaseFirestore.instance
            .collection("seasons")
            .doc(seasonId)
            .update({"status": "inactive"});
      } else {
        // Toggle on, deactivate others first
        final activeSeasons = await FirebaseFirestore.instance
            .collection("seasons")
            .where("status", isEqualTo: "active")
            .get();
        final batch = FirebaseFirestore.instance.batch();
        for (var doc in activeSeasons.docs) {
          batch.update(doc.reference, {"status": "inactive"});
        }
        batch.update(
          FirebaseFirestore.instance.collection("seasons").doc(seasonId),
          {"status": "active"},
        );
        await batch.commit();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Season status updated successfully!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error updating season status: $e"),
          backgroundColor: AppColors.heartRed,
        ),
      );
    }
  }

  void _showAddEditBottomSheet({
    String? editId,
    Map<String, dynamic>? initialData,
  }) {
    if (initialData != null) {
      _nameController.text = initialData["name"] ?? "";
      _startDate =
          DateTime.tryParse(initialData["startDate"] ?? "") ?? DateTime.now();
      _endDate =
          DateTime.tryParse(initialData["endDate"] ?? "") ?? DateTime.now();
      _isActive = initialData["status"] == "active";
    } else {
      _nameController.clear();
      _startDate = DateTime.now();
      _endDate = DateTime.now().add(const Duration(days: 90));
      _isActive = false;
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBorder : Colors.grey[300],
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                ),
                SizedBox(height: 15.h),
                Text(
                  editId == null ? "Create New Season" : "Edit Season Details",
                  style: GoogleFonts.cairo(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.softGold : AppColors.primaryColor,
                  ),
                ),
                SizedBox(height: 15.h),
                TextFormField(
                  controller: _nameController,
                  style: GoogleFonts.cairo(color: textColor),
                  decoration: InputDecoration(
                    labelText: "Season Name",
                    labelStyle: GoogleFonts.cairo(color: mutedColor),
                    prefixIcon: HugeIcon(
                      icon: HugeIcons.strokeRoundedFile01,
                      size: 20.r,
                      color: AppColors.softGold,
                    ),
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
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? "Season name is required"
                      : null,
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _selectDate(context, true),
                        icon: HugeIcon(
                          icon: HugeIcons.strokeRoundedCalendar01,
                          size: 16.r,
                          color: AppColors.softGold,
                        ),
                        label: Text(
                          "Start: ${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}",
                          style: GoogleFonts.cairo(
                            fontSize: 11.sp,
                            color: textColor,
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
                    SizedBox(width: 8.w),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _selectDate(context, false),
                        icon: HugeIcon(
                          icon: HugeIcons.strokeRoundedCalendar01,
                          size: 16.r,
                          color: AppColors.softGold,
                        ),
                        label: Text(
                          "End: ${_endDate.year}-${_endDate.month.toString().padLeft(2, '0')}-${_endDate.day.toString().padLeft(2, '0')}",
                          style: GoogleFonts.cairo(
                            fontSize: 11.sp,
                            color: textColor,
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
                SizedBox(height: 10.h),
                StatefulBuilder(
                  builder: (context, setStateSheet) {
                    return SwitchListTile(
                      title: Text(
                        "Set as Active Season",
                        style: GoogleFonts.cairo(
                          fontSize: 15.sp,
                          color: textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        "This deactivates all other seasons",
                        style: GoogleFonts.cairo(
                          fontSize: 12.sp,
                          color: mutedColor,
                        ),
                      ),
                      value: _isActive,
                      activeColor: AppColors.softGold,
                      onChanged: (val) {
                        setStateSheet(() {
                          _isActive = val;
                        });
                      },
                    );
                  },
                ),
                SizedBox(height: 15.h),
                SizedBox(
                  width: double.infinity,
                  height: 48.h,
                  child: ElevatedButton(
                    onPressed: () => _saveSeason(editId: editId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.softGold,
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Text(
                      "Save Season",
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
        );
      },
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
    final mutedColor = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

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
          "Seasons Management",
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
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("seasons")
              .orderBy("createdAt", descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.softGold),
              );
            }

            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return EmptyState(
                title: "No attendance seasons registered.",
                hugeIcon: HugeIcons.strokeRoundedGrid,
              );
            }

            return ListView.separated(
              physics: const BouncingScrollPhysics(),
              itemCount: docs.length,
              separatorBuilder: (_, __) => SizedBox(height: 12.h),
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data() as Map<String, dynamic>;
                final name = data["name"] ?? "";
                final start = data["startDate"] ?? "";
                final end = data["endDate"] ?? "";
                final status = data["status"] ?? "inactive";
                final isActive = status == "active";

                return GlassCard(
                  padding: EdgeInsets.all(14.r),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    name,
                                    style: GoogleFonts.cairo(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16.sp,
                                      color: textColor,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8.w,
                                    vertical: 4.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? Colors.green.withValues(alpha: 0.15)
                                        : mutedColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8.r),
                                    border: Border.all(
                                      color: isActive
                                          ? Colors.green.withValues(alpha: 0.4)
                                          : borderColor,
                                    ),
                                  ),
                                  child: Text(
                                    isActive ? "Active" : "Inactive",
                                    style: GoogleFonts.cairo(
                                      color: isActive
                                          ? Colors.green
                                          : mutedColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11.sp,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              "Period: $start to $end",
                              style: GoogleFonts.cairo(
                                fontSize: 12.sp,
                                color: mutedColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch(
                            value: isActive,
                            activeColor: AppColors.softGold,
                            onChanged: (val) {
                              _toggleSeasonActive(doc.id, isActive);
                            },
                          ),
                          IconButton(
                            icon: const HugeIcon(
                              icon: HugeIcons.strokeRoundedEdit01,
                              color: AppColors.softGold,
                            ),
                            onPressed: () => _showAddEditBottomSheet(
                              editId: doc.id,
                              initialData: data,
                            ),
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
    );
  }
}
