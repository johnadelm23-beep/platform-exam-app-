import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';
import 'package:platformexamapp/core/widgets/glass_card.dart';

class AdminPrivilegesSheet extends StatefulWidget {
  const AdminPrivilegesSheet({
    super.key,
    required this.targetUserDocId,
    required this.targetUserData,
  });

  final String targetUserDocId;
  final Map<String, dynamic> targetUserData;

  @override
  State<AdminPrivilegesSheet> createState() => _AdminPrivilegesSheetState();
}

class _AdminPrivilegesSheetState extends State<AdminPrivilegesSheet> {
  late String _selectedRole;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final bool isAdmin = widget.targetUserData["isAdmin"] == true;
    final bool isSubAdmin =
        !isAdmin &&
        ((widget.targetUserData["subAdmin"] == true) ||
            (widget.targetUserData["isSubAdmin"] == true));

    if (isAdmin) {
      _selectedRole = "admin";
    } else if (isSubAdmin) {
      _selectedRole = "subadmin";
    } else {
      _selectedRole = "user";
    }
  }

  Future<void> _updatePrivileges() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final bool newIsAdmin = _selectedRole == "admin";
      final bool newIsSubAdmin = _selectedRole == "subadmin";

      await FirebaseFirestore.instance
          .collection("users")
          .doc(widget.targetUserDocId)
          .update({
            "isAdmin": newIsAdmin,
            "subAdmin": newIsSubAdmin,
            "isSubAdmin": newIsSubAdmin,
          });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("User privileges updated successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to update privileges: $e"),
            backgroundColor: AppColors.heartRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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

    final name = widget.targetUserData["name"] ?? "User";
    final email = widget.targetUserData["email"] ?? "No email provided";

    return Container(
      padding: EdgeInsets.only(
        top: 20.r,
        left: 20.r,
        right: 20.r,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24.r,
      ),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32.r),
          topRight: Radius.circular(32.r),
        ),
        border: Border.all(color: borderColor),
      ),
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
                  color: isDark ? AppColors.darkBorder : Colors.grey[300],
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),

            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    color: AppColors.softGold.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const HugeIcon(
                    icon: HugeIcons.strokeRoundedSettings01,
                    color: AppColors.softGold,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Manage Admin Privileges",
                        style: GoogleFonts.cairo(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      Text(
                        name,
                        style: GoogleFonts.cairo(
                          fontSize: 14.sp,
                          color: AppColors.softGold,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 6.h),
            Text(
              email,
              style: GoogleFonts.cairo(fontSize: 12.sp, color: mutedColor),
            ),

            SizedBox(height: 16.h),
            Divider(color: borderColor),
            SizedBox(height: 12.h),

            Text(
              "Select Role Level:",
              style: GoogleFonts.cairo(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            SizedBox(height: 10.h),

            _buildRoleOption(
              value: "admin",
              title: "Main Admin",
              description:
                  "Full control over content creation, exams, events, seasons, and user privilege management.",
              color: AppColors.heartRed,
              inputBg: inputBg,
              borderColor: borderColor,
              textColor: textColor,
              mutedColor: mutedColor,
            ),
            SizedBox(height: 10.h),

            _buildRoleOption(
              value: "subadmin",
              title: "Sub Admin",
              description:
                  "Access to QR Scanner, Attendance Dashboard, Follow Up, Users List, and Reports.",
              color: Colors.orange.shade400,
              inputBg: inputBg,
              borderColor: borderColor,
              textColor: textColor,
              mutedColor: mutedColor,
            ),
            SizedBox(height: 10.h),

            _buildRoleOption(
              value: "user",
              title: "Regular Member",
              description:
                  "Standard member access to exams, attendance streak, daily content, and personal profile.",
              color: AppColors.successGreen,
              inputBg: inputBg,
              borderColor: borderColor,
              textColor: textColor,
              mutedColor: mutedColor,
            ),

            SizedBox(height: 24.h),

            SizedBox(
              width: double.infinity,
              height: 48.h,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updatePrivileges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.softGold,
                  foregroundColor: Colors.black87,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.black87,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        "Save Privileges",
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
  }

  Widget _buildRoleOption({
    required String value,
    required String title,
    required String description,
    required Color color,
    required Color inputBg,
    required Color borderColor,
    required Color textColor,
    required Color mutedColor,
  }) {
    final isSelected = _selectedRole == value;

    return GlassCard(
      onTap: () {
        setState(() {
          _selectedRole = value;
        });
      },
      customBgColor: isSelected ? color.withValues(alpha: 0.12) : inputBg,
      customBorderColor: isSelected ? color : borderColor,
      padding: EdgeInsets.all(12.r),
      borderRadius: 14.r,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Radio<String>(
            value: value,
            groupValue: _selectedRole,
            activeColor: color,
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedRole = val;
                });
              }
            },
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    fontSize: 15.sp,
                    color: isSelected ? color : textColor,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  description,
                  style: GoogleFonts.cairo(fontSize: 12.sp, color: mutedColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
