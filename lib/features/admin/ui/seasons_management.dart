import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';

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
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2035),
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
    final userDoc = await FirebaseFirestore.instance.collection("users").doc(currentUser.uid).get();
    if (userDoc.data()?["isAdmin"] != true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Permission denied: Main Admin only."), backgroundColor: Colors.red),
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
          backgroundColor: Colors.red,
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
          backgroundColor: Colors.red,
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
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30.r),
              topRight: Radius.circular(30.r),
            ),
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
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                ),
                SizedBox(height: 15.h),
                Text(
                  editId == null ? "Create New Season" : "Edit Season Details",
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                ),
                SizedBox(height: 15.h),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: "Season Name",
                    prefixIcon: HugeIcon(
                      icon: HugeIcons.strokeRoundedFile01,
                      size: 20.r,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
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
                        ),
                        label: Text(
                          "Start: ${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}",
                          style: TextStyle(fontSize: 12.sp),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
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
                        ),
                        label: Text(
                          "End: ${_endDate.year}-${_endDate.month.toString().padLeft(2, '0')}-${_endDate.day.toString().padLeft(2, '0')}",
                          style: TextStyle(fontSize: 12.sp),
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
                SizedBox(height: 10.h),
                StatefulBuilder(
                  builder: (context, setStateSheet) {
                    return SwitchListTile(
                      title: Text(
                        "Set as Active Season",
                        style: TextStyle(fontSize: 18.sp),
                      ),
                      subtitle: const Text(
                        "This deactivates all other seasons",
                      ),
                      value: _isActive,
                      activeColor: AppColors.primaryColor,
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
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Text(
                      "Save Season",
                      style: TextStyle(fontWeight: .bold, fontSize: 25.sp),
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
          "Seasons Management",
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
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("seasons")
              .orderBy("createdAt", descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primaryColor),
              );
            }

            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedGrid,
                      size: 50.r,
                      color: Colors.grey[300],
                    ),
                    SizedBox(height: 10.h),
                    const Text(
                      "No attendance seasons registered.",
                      style: TextStyle(color: Colors.grey),
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
                final name = data["name"] ?? "";
                final start = data["startDate"] ?? "";
                final end = data["endDate"] ?? "";
                final status = data["status"] ?? "inactive";
                final isActive = status == "active";

                return Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.r),
                  ),
                  child: ListTile(
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? Colors.green[50]
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            isActive ? "Active" : "Inactive",
                            style: TextStyle(
                              color: isActive
                                  ? Colors.green[700]
                                  : Colors.grey[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 11.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      "Period: $start to $end",
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: isActive,
                          activeColor: AppColors.primaryColor,
                          onChanged: (val) {
                            _toggleSeasonActive(doc.id, isActive);
                          },
                        ),
                        IconButton(
                          icon: const HugeIcon(
                            icon: HugeIcons.strokeRoundedEdit01,
                            color: Colors.blue,
                          ),
                          onPressed: () => _showAddEditBottomSheet(
                            editId: doc.id,
                            initialData: data,
                          ),
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
