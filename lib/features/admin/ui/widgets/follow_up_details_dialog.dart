import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';
import 'package:platformexamapp/features/admin/cubit/follow_up_cubit.dart';
import 'package:platformexamapp/features/auth/data/models/user_data.dart';
import 'package:platformexamapp/features/profile/ui/widgets/user_avatar.dart';

class FollowUpDetailsDialog extends StatefulWidget {
  final UserData user;

  const FollowUpDetailsDialog({
    super.key,
    required this.user,
  });

  static Future<void> show(BuildContext context, UserData user) {
    final cubit = context.read<FollowUpCubit>();
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => BlocProvider.value(
        value: cubit,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 16.h),
          child: FollowUpDetailsDialog(user: user),
        ),
      ),
    );
  }

  @override
  State<FollowUpDetailsDialog> createState() => _FollowUpDetailsDialogState();
}

class _FollowUpDetailsDialogState extends State<FollowUpDetailsDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _notesController;
  late TextEditingController _servantNotesController;

  late String _followUpStatus;
  late bool _needVisit;
  DateTime? _lastCallDate;
  DateTime? _lastVisitDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _phoneController = TextEditingController(text: u.phone ?? '');
    _addressController = TextEditingController(text: u.address ?? '');
    _notesController = TextEditingController(text: u.notes ?? '');
    _servantNotesController = TextEditingController(text: u.servantNotes ?? '');

    _followUpStatus = u.followUpStatus ?? "Regular";
    _needVisit = u.needVisit ?? false;
    _lastCallDate = u.lastCallDate;
    _lastVisitDate = u.lastVisitDate;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    _servantNotesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isCallDate) async {
    final initialDate = (isCallDate ? _lastCallDate : _lastVisitDate) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isCallDate) {
          _lastCallDate = picked;
        } else {
          _lastVisitDate = picked;
        }
      });
    }
  }

  Future<void> _saveFollowUpData() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final updatedData = {
      'phone': _phoneController.text.trim(),
      'address': _addressController.text.trim(),
      'followUpStatus': _followUpStatus,
      'needVisit': _needVisit,
      'notes': _notesController.text.trim(),
      'servantNotes': _servantNotesController.text.trim(),
      'lastCallDate': _lastCallDate == null ? null : Timestamp.fromDate(_lastCallDate!),
      'lastVisitDate': _lastVisitDate == null ? null : Timestamp.fromDate(_lastVisitDate!),
      'lastContact': Timestamp.fromDate(DateTime.now()),
    };

    final uid = widget.user.uid ?? '';
    final success = await context.read<FollowUpCubit>().saveUserFollowUp(uid, updatedData);

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10.w),
                Expanded(child: Text("follow_up_saved_success".tr())),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(maxHeight: ScreenUtil().screenHeight * 0.85),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Bar
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20.r),
                topRight: Radius.circular(20.r),
              ),
            ),
            child: Row(
              children: [
                UserAvatar(imageUrl: widget.user.profileImage, radius: 20.r),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    widget.user.name ?? "follow_up".tr(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),

          // Scrollable Form Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20.r),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Phone Number
                    _buildTextField(
                      _phoneController,
                      "phone_number".tr(),
                      Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),

                    // Address
                    _buildTextField(
                      _addressController,
                      "address".tr(),
                      Icons.location_on_outlined,
                    ),

                    SizedBox(height: 10.h),

                    // Follow-up Status Dropdown
                    Text(
                      "follow_up_status".tr(),
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[100],
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[300]!),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _getNormalizedStatusKey(_followUpStatus),
                          isExpanded: true,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          dropdownColor: isDark ? const Color(0xFF2E2E2E) : Colors.white,
                          onChanged: (val) {
                            if (val != null) setState(() => _followUpStatus = val);
                          },
                          items: [
                            DropdownMenuItem(value: "Excellent", child: Text("status_excellent".tr())),
                            DropdownMenuItem(value: "Regular", child: Text("status_regular".tr())),
                            DropdownMenuItem(value: "Needs Follow-up", child: Text("status_needs_follow_up".tr())),
                            DropdownMenuItem(value: "Urgent", child: Text("status_urgent".tr())),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 14.h),

                    // Need Visit Switch
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[100],
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[300]!),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              HugeIcon(
                                icon: HugeIcons.strokeRoundedHome01,
                                color: AppColors.primaryColor,
                                size: 20.r,
                              ),
                              SizedBox(width: 10.w),
                              Text(
                                "need_visit".tr(),
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          Switch(
                            value: _needVisit,
                            activeThumbColor: AppColors.primaryColor,
                            onChanged: (val) => setState(() => _needVisit = val),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 14.h),

                    // Dates Row (Last Call & Last Visit)
                    Row(
                      children: [
                        Expanded(
                          child: _buildDateTile(
                            "last_call".tr(),
                            _lastCallDate,
                            () => _selectDate(context, true),
                            isDark,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: _buildDateTile(
                            "last_visit".tr(),
                            _lastVisitDate,
                            () => _selectDate(context, false),
                            isDark,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 14.h),

                    // Notes
                    _buildTextField(
                      _notesController,
                      "notes".tr(),
                      Icons.note_alt_outlined,
                      maxLines: 3,
                    ),

                    // Servant Notes
                    _buildTextField(
                      _servantNotesController,
                      "servant_notes".tr(),
                      Icons.security_outlined,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Buttons Row: Cancel & Save
          Padding(
            padding: EdgeInsets.all(16.r),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48.h,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                        side: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[400]!),
                      ),
                      child: Text(
                        "cancel".tr(),
                        style: TextStyle(
                          fontSize: 15.sp,
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: SizedBox(
                    height: 48.h,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveFollowUpData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                        elevation: 2,
                      ),
                      child: _isSaving
                          ? SizedBox(
                              width: 20.r,
                              height: 20.r,
                              child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              "save".tr(),
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getNormalizedStatusKey(String current) {
    if (current == "Excellent" || current == "ممتاز") return "Excellent";
    if (current == "Needs Follow-up" || current == "بحاجة لافتقاد") return "Needs Follow-up";
    if (current == "Urgent" || current == "حالة عاجلة") return "Urgent";
    return "Regular";
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: TextStyle(fontSize: 14.sp, color: isDark ? Colors.white : Colors.black87),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20.r, color: isDark ? Colors.grey[400] : Colors.grey[600]),
          filled: true,
          fillColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey[100],
          contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildDateTile(String label, DateTime? date, VoidCallback onTap, bool isDark) {
    final dateStr = date == null ? "not_set".tr() : DateFormat("yyyy/MM/dd").format(date);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[100],
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[300]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11.sp, color: isDark ? Colors.grey[400] : Colors.grey[600])),
            SizedBox(height: 4.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Icon(Icons.calendar_month_outlined, size: 16.r, color: AppColors.primaryColor),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
