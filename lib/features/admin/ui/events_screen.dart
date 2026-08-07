import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';
import 'package:platformexamapp/core/services/offline_sync_service.dart';

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
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
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
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
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
    final userDoc = await FirebaseFirestore.instance.collection("users").doc(currentUser.uid).get();
    if (userDoc.data()?["isAdmin"] != true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Permission denied: Main Admin only."), backgroundColor: Colors.red),
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
          backgroundColor: Colors.red,
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
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAddEventBottomSheet() {
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
                        "create_new_event".tr(),
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      SizedBox(height: 15.h),
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: "event_title".tr(),
                          prefixIcon: HugeIcon(icon: HugeIcons.strokeRoundedFile01, size: 20.r),
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
                        controller: _descController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: "description".tr(),
                          prefixIcon: HugeIcon(icon: HugeIcons.strokeRoundedEdit01, size: 20.r),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
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
                                color: Colors.black,
                              ),
                              label: Text(
                                "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: .bold,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 12.h),
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
                                color: Colors.black,
                              ),
                              label: Text(
                                _selectedTime.format(context),
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: .bold,
                                ),
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
                      SizedBox(height: 15.h),
                      Text(
                        "event_type".tr(),
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: 8.h),
                      DropdownButtonFormField<String>(
                        value: _selectedType,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'friday_meeting',
                            child: Text('friday_meeting'.tr()),
                          ),
                          DropdownMenuItem(
                            value: 'sunday_activity',
                            child: Text('sunday_activity'.tr()),
                          ),
                          DropdownMenuItem(
                            value: 'conference',
                            child: Text('conference'.tr()),
                          ),
                          DropdownMenuItem(
                            value: 'camp',
                            child: Text('camp'.tr()),
                          ),
                          DropdownMenuItem(
                            value: 'trip',
                            child: Text('trip'.tr()),
                          ),
                          DropdownMenuItem(
                            value: 'special_meeting',
                            child: Text('special_meeting'.tr()),
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
                      SwitchListTile(
                        title: Text("make_active_event".tr()),
                        subtitle: Text("automaticaly_deactive".tr()),
                        value: _isActive,
                        activeColor: AppColors.primaryColor,
                        onChanged: (val) {
                          setSheetState(() {
                            _isActive = val;
                          });
                        },
                      ),
                      SizedBox(height: 15.h),
                      SizedBox(
                        width: double.infinity,
                        height: 48.h,
                        child: ElevatedButton(
                          onPressed: _createNewEvent,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          child: Text(
                            "create_event".tr(),
                            style: TextStyle(
                              fontWeight: .bold,
                              fontSize: 20.sp,
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
          "events_management".tr(),
          style: TextStyle(color: Colors.white, fontWeight: .bold),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEventBottomSheet,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primaryColor,
        child: const Icon(Icons.add),
      ),
      body: Container(
        margin: EdgeInsets.only(top: 10.h),
        padding: EdgeInsets.all(16.r),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30.r),
            topRight: Radius.circular(30.r),
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("events")
              .orderBy("createdAt", descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedCalendar01,
                      size: 60.r,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      "No events created yet.",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16.sp,
                      ),
                    ),
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

                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.r),
                  ),
                  color: Colors.white,
                  elevation: 2,
                  child: Padding(
                    padding: EdgeInsets.all(12.r),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: typeColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Text(
                                typeLabel,
                                style: TextStyle(
                                  color: typeColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.sp,
                                ),
                              ),
                            ),
                            Switch(
                              value: isActive,
                              activeColor: AppColors.primaryColor,
                              onChanged: (val) {
                                _toggleEventActive(doc.id, isActive);
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          desc,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 10.h),
                        Row(
                          children: [
                            HugeIcon(
                              icon: HugeIcons.strokeRoundedCalendar01,
                              size: 16.r,
                              color: Colors.grey,
                            ),
                            SizedBox(width: 5.w),
                            Text(
                              date,
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: Colors.grey[700],
                              ),
                            ),
                            SizedBox(width: 15.w),
                            HugeIcon(
                              icon: HugeIcons.strokeRoundedClock01,
                              size: 16.r,
                              color: Colors.grey,
                            ),
                            SizedBox(width: 5.w),
                            Text(
                              time,
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: Colors.grey[700],
                              ),
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
        ),
      ),
    );
  }
}
