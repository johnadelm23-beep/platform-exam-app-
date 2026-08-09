import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';
import 'package:platformexamapp/core/services/offline_sync_service.dart';
import 'package:platformexamapp/core/widgets/empty_state.dart';
import 'package:platformexamapp/core/widgets/glass_card.dart';

class EventsManagementScreen extends StatefulWidget {
  const EventsManagementScreen({super.key});

  @override
  State<EventsManagementScreen> createState() => _EventsManagementScreenState();
}

class _EventsManagementScreenState extends State<EventsManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _selectedType = 'friday_meeting'; // default type
  bool _isActive = true;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
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
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
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
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _createNewEvent() async {
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

    final title = _titleController.text.trim();
    final description = _descController.text.trim();
    final dateStr =
        "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";
    final timeStr =
        "${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}";

    try {
      final docRef = FirebaseFirestore.instance.collection("events").doc();
      final eventId = docRef.id;

      // If this event is active, make all other events inactive
      if (_isActive) {
        final activeEvents = await FirebaseFirestore.instance
            .collection("events")
            .where("isActive", isEqualTo: true)
            .get();

        final batch = FirebaseFirestore.instance.batch();
        for (var doc in activeEvents.docs) {
          batch.update(doc.reference, {"isActive": false});
        }
        await batch.commit();
      }

      final seasonId = await OfflineSyncService.getActiveSeasonId();

      await docRef.set({
        "id": eventId,
        "title": title,
        "description": description,
        "date": dateStr,
        "time": timeStr,
        "type": _selectedType,
        "isActive": _isActive,
        "seasonId": seasonId,
        "createdAt": FieldValue.serverTimestamp(),
      });

      _titleController.clear();
      _descController.clear();
      setState(() {
        _isActive = true;
      });

      if (mounted) {
        Navigator.pop(context); // Close sheet
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Event created successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to create event: $e"),
          backgroundColor: AppColors.heartRed,
        ),
      );
    }
  }

  Future<void> _toggleEventActive(String eventId, bool currentStatus) async {
    try {
      if (currentStatus) {
        // Deactivate this event, nothing else changes
        await FirebaseFirestore.instance
            .collection("events")
            .doc(eventId)
            .update({"isActive": false});
      } else {
        // Activating this event requires deactivating all other active events
        final activeEvents = await FirebaseFirestore.instance
            .collection("events")
            .where("isActive", isEqualTo: true)
            .get();

        final batch = FirebaseFirestore.instance.batch();
        for (var doc in activeEvents.docs) {
          batch.update(doc.reference, {"isActive": false});
        }
        batch.update(
          FirebaseFirestore.instance.collection("events").doc(eventId),
          {"isActive": true},
        );
        await batch.commit();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error updating event status: $e"),
          backgroundColor: AppColors.heartRed,
        ),
      );
    }
  }

  void _showAddEventBottomSheet() {
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
          builder: (context, setSheetState) {
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
                        "create_new_event".tr(),
                        style: GoogleFonts.cairo(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.softGold
                              : AppColors.primaryColor,
                        ),
                      ),
                      SizedBox(height: 15.h),
                      TextFormField(
                        controller: _titleController,
                        style: GoogleFonts.cairo(color: textColor),
                        decoration: InputDecoration(
                          labelText: "event_title".tr(),
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
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? "Title is required"
                            : null,
                      ),
                      SizedBox(height: 12.h),
                      TextFormField(
                        controller: _descController,
                        maxLines: 2,
                        style: GoogleFonts.cairo(color: textColor),
                        decoration: InputDecoration(
                          labelText: "description".tr(),
                          labelStyle: GoogleFonts.cairo(color: mutedColor),
                          prefixIcon: HugeIcon(
                            icon: HugeIcons.strokeRoundedEdit01,
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
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? "Description is required"
                            : null,
                      ),
                      SizedBox(height: 12.h),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                await _selectDate(context);
                                setSheetState(() {});
                              },
                              icon: const HugeIcon(
                                icon: HugeIcons.strokeRoundedCalendar01,
                                color: AppColors.softGold,
                              ),
                              label: Text(
                                "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}",
                                style: GoogleFonts.cairo(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.sp,
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
                          SizedBox(width: 10.w),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                await _selectTime(context);
                                setSheetState(() {});
                              },
                              icon: const HugeIcon(
                                icon: HugeIcons.strokeRoundedClock01,
                                color: AppColors.softGold,
                              ),
                              label: Text(
                                _selectedTime.format(context),
                                style: GoogleFonts.cairo(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.sp,
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
                      SizedBox(height: 15.h),
                      Text(
                        "event_type".tr(),
                        style: GoogleFonts.cairo(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: mutedColor,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      DropdownButtonFormField<String>(
                        value: _selectedType,
                        dropdownColor: surfaceColor,
                        style: GoogleFonts.cairo(
                          color: textColor,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
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
                        items: [
                          DropdownMenuItem(
                            value: 'friday_meeting',
                            child: Text(
                              'friday_meeting'.tr(),
                              style: GoogleFonts.cairo(color: textColor),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'sunday_activity',
                            child: Text(
                              'sunday_activity'.tr(),
                              style: GoogleFonts.cairo(color: textColor),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'conference',
                            child: Text(
                              'conference'.tr(),
                              style: GoogleFonts.cairo(color: textColor),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'camp',
                            child: Text(
                              'camp'.tr(),
                              style: GoogleFonts.cairo(color: textColor),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'trip',
                            child: Text(
                              'trip'.tr(),
                              style: GoogleFonts.cairo(color: textColor),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'special_meeting',
                            child: Text(
                              'special_meeting'.tr(),
                              style: GoogleFonts.cairo(color: textColor),
                            ),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setSheetState(() {
                              _selectedType = val;
                            });
                          }
                        },
                      ),
                      SizedBox(height: 10.h),
                      Material(
                        color: Colors.transparent,
                        child: SwitchListTile(
                          title: Text(
                            "make_active_event".tr(),
                            style: GoogleFonts.cairo(
                              fontSize: 15.sp,
                              color: textColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            "automaticaly_deactive".tr(),
                            style: GoogleFonts.cairo(
                              fontSize: 12.sp,
                              color: mutedColor,
                            ),
                          ),
                          value: _isActive,
                          activeColor: AppColors.softGold,
                          onChanged: (val) {
                            setSheetState(() {
                              _isActive = val;
                            });
                          },
                        ),
                      ),
                      SizedBox(height: 15.h),
                      SizedBox(
                        width: double.infinity,
                        height: 48.h,
                        child: ElevatedButton(
                          onPressed: _createNewEvent,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.softGold,
                            foregroundColor: Colors.black87,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          child: Text(
                            "create_event".tr(),
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
          "events_management".tr(),
          style: GoogleFonts.cairo(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEventBottomSheet,
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
              .collection("events")
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
                title: "No events created yet.",
                hugeIcon: HugeIcons.strokeRoundedCalendar01,
              );
            }

            return ListView.separated(
              physics: const BouncingScrollPhysics(),
              itemCount: docs.length,
              separatorBuilder: (_, __) => SizedBox(height: 12.h),
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data() as Map<String, dynamic>;
                final title = data["title"] ?? "";
                final desc = data["description"] ?? "";
                final date = data["date"] ?? "";
                final time = data["time"] ?? "";
                final type = data["type"] ?? "";
                final isActive = data["isActive"] ?? false;

                Color typeColor;
                String typeLabel;
                switch (type) {
                  case 'friday_meeting':
                    typeColor = Colors.blue;
                    typeLabel = 'Friday Meeting';
                    break;
                  case 'sunday_activity':
                    typeColor = Colors.orange;
                    typeLabel = 'Sunday Activity';
                    break;
                  case 'conference':
                    typeColor = Colors.teal;
                    typeLabel = 'Conference';
                    break;
                  case 'camp':
                    typeColor = Colors.green;
                    typeLabel = 'Camp';
                    break;
                  case 'trip':
                    typeColor = Colors.indigo;
                    typeLabel = 'Trip';
                    break;
                  case 'special_meeting':
                    typeColor = Colors.purple;
                    typeLabel = 'Special Meeting';
                    break;
                  default:
                    typeColor = Colors.grey;
                    typeLabel = 'Other Event';
                }

                return GlassCard(
                  padding: EdgeInsets.all(14.r),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: typeColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10.r),
                              border: Border.all(
                                color: typeColor.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              typeLabel,
                              style: GoogleFonts.cairo(
                                color: typeColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 11.sp,
                              ),
                            ),
                          ),
                          Switch(
                            value: isActive,
                            activeColor: AppColors.softGold,
                            onChanged: (val) {
                              _toggleEventActive(doc.id, isActive);
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        title,
                        style: GoogleFonts.cairo(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      if (desc.isNotEmpty) ...[
                        SizedBox(height: 4.h),
                        Text(
                          desc,
                          style: GoogleFonts.cairo(
                            fontSize: 13.sp,
                            color: mutedColor,
                          ),
                        ),
                      ],
                      SizedBox(height: 10.h),
                      Row(
                        children: [
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedCalendar01,
                            size: 16.r,
                            color: AppColors.softGold,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            date,
                            style: GoogleFonts.cairo(
                              fontSize: 12.sp,
                              color: mutedColor,
                            ),
                          ),
                          SizedBox(width: 16.w),
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedClock01,
                            size: 16.r,
                            color: AppColors.softGold,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            time,
                            style: GoogleFonts.cairo(
                              fontSize: 12.sp,
                              color: mutedColor,
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
