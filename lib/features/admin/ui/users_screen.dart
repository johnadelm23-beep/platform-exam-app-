import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';
import 'package:platformexamapp/core/widgets/empty_state.dart';
import 'package:platformexamapp/core/widgets/glass_card.dart';
import 'package:platformexamapp/core/widgets/loading_state.dart';
import 'package:platformexamapp/features/auth/data/models/user_data.dart';
import 'package:platformexamapp/features/admin/ui/widgets/admin_privileges_sheet.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key, this.currentUser});

  final UserData? currentUser;

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  late final Stream<QuerySnapshot> _usersStream;

  @override
  void initState() {
    super.initState();
    _usersStream = FirebaseFirestore.instance.collection("users").snapshots();
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
    final mutedColor = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;

    return Scaffold(
      backgroundColor: pageBg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(16.r),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: EdgeInsets.all(10.r),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.08)
                            : Colors.black.withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_back_ios,
                        color: textColor,
                        size: 18.r,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    "All Users",
                    style: GoogleFonts.cairo(
                      fontSize: 22.sp,
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32.r),
                    topRight: Radius.circular(32.r),
                  ),
                  border: Border(top: BorderSide(color: borderColor, width: 1)),
                ),
                child: StreamBuilder<QuerySnapshot>(
                  stream: _usersStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          "Error loading users",
                          style: GoogleFonts.cairo(color: AppColors.heartRed),
                        ),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const LoadingState();
                    }

                    final users = snapshot.data!.docs;

                    if (users.isEmpty) {
                      return EmptyState(
                        title: "No Users Found",
                        icon: Icons.person_off_outlined,
                      );
                    }

                    return ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      itemCount: users.length,
                      separatorBuilder: (_, __) => SizedBox(height: 12.h),
                      itemBuilder: (context, index) {
                        final userDoc = users[index];
                        final user = userDoc.data() as Map<String, dynamic>;

                        final name = user["name"] ?? "No Name";
                        final email = user["email"] ?? "No Email";
                        final isAdmin = user["isAdmin"] == true;
                        final isSubAdmin =
                            !isAdmin &&
                            (user["subAdmin"] == true ||
                                user["isSubAdmin"] == true);
                        final String roleText = isAdmin
                            ? "Admin"
                            : isSubAdmin
                            ? "Sub Admin"
                            : "User";
                        final Color roleColor = isAdmin
                            ? AppColors.heartRed
                            : isSubAdmin
                            ? Colors.orange.shade400
                            : AppColors.successGreen;

                        return GlassCard(
                          padding: EdgeInsets.all(14.r),
                          borderRadius: 18.r,
                          child: Row(
                            children: [
                              Container(
                                width: 48.r,
                                height: 48.r,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: roleColor.withOpacity(0.15),
                                  border: Border.all(
                                    color: roleColor.withOpacity(0.4),
                                    width: 1.5,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    name.isNotEmpty
                                        ? name[0].toUpperCase()
                                        : "?",
                                    style: GoogleFonts.cairo(
                                      color: roleColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18.sp,
                                    ),
                                  ),
                                ),
                              ),

                              SizedBox(width: 12.w),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: GoogleFonts.cairo(
                                        color: textColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15.sp,
                                      ),
                                    ),
                                    SizedBox(height: 2.h),
                                    Text(
                                      email,
                                      style: GoogleFonts.cairo(
                                        color: mutedColor,
                                        fontSize: 12.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10.w,
                                  vertical: 4.h,
                                ),
                                decoration: BoxDecoration(
                                  color: roleColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                child: Text(
                                  roleText,
                                  style: GoogleFonts.cairo(
                                    color: roleColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11.sp,
                                  ),
                                ),
                              ),

                              if (widget.currentUser?.isAdminVal == true)
                                IconButton(
                                  icon: const HugeIcon(
                                    icon: HugeIcons.strokeRoundedSettings01,
                                    color: AppColors.softGold,
                                  ),
                                  onPressed: () {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (_) => AdminPrivilegesSheet(
                                        targetUserDocId: userDoc.id,
                                        targetUserData: user,
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
