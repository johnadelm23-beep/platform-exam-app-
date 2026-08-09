import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';
import 'package:platformexamapp/core/widgets/glass_card.dart';
import 'package:platformexamapp/features/auth/data/models/user_data.dart';

class ProfileQrDialog extends StatelessWidget {
  final UserData user;
  final String qrPayload;
  final VoidCallback onSave;
  final VoidCallback onShare;

  const ProfileQrDialog({
    super.key,
    required this.user,
    required this.qrPayload,
    required this.onSave,
    required this.onShare,
  });

  static Future<void> show({
    required BuildContext context,
    required UserData user,
    required String qrPayload,
    required VoidCallback onSave,
    required VoidCallback onShare,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Dismiss QR",
      barrierColor: Colors.black.withOpacity(0.6),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return ProfileQrDialog(
          user: user,
          qrPayload: qrPayload,
          onSave: onSave,
          onShare: onShare,
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(
              CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
            ),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextMain : AppColors.lightTextMain;

    final screenSize = MediaQuery.of(context).size;
    final qrSize = (screenSize.width * 0.72).clamp(240.0, 320.0);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(color: Colors.black.withOpacity(0.6)),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
              child: GlassCard(
                padding: EdgeInsets.all(24.r),
                borderRadius: 28.r,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header Bar with Close Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8.r),
                              decoration: BoxDecoration(
                                color: AppColors.softGold.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: HugeIcon(
                                icon: HugeIcons.strokeRoundedQrCode,
                                color: AppColors.softGold,
                                size: 20.r,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              "profile".tr(),
                              style: GoogleFonts.cairo(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.softGold,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close, size: 22.r, color: textColor),
                          style: IconButton.styleFrom(
                            backgroundColor: isDark
                                ? Colors.white.withOpacity(0.08)
                                : Colors.black.withOpacity(0.05),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 16.h),

                    // User Info
                    CircleAvatar(
                      radius: 36.r,
                      backgroundColor: AppColors.softGold.withOpacity(0.15),
                      backgroundImage:
                          user.profileImage != null &&
                              user.profileImage!.isNotEmpty
                          ? NetworkImage(user.profileImage!)
                          : null,
                      child:
                          user.profileImage == null ||
                              user.profileImage!.isEmpty
                          ? HugeIcon(
                              icon: HugeIcons.strokeRoundedUser02,
                              size: 36.r,
                              color: AppColors.softGold,
                            )
                          : null,
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      user.name ?? "User",
                      style: GoogleFonts.cairo(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 4.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.softGold.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: AppColors.softGold.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        "ID: ${user.humanReadableId ?? 'EGT000000'}",
                        style: GoogleFonts.cairo(
                          fontSize: 13.sp,
                          color: AppColors.softGold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    SizedBox(height: 20.h),

                    // Large Hero QR View
                    Hero(
                      tag: 'profile_qr_hero',
                      child: Container(
                        padding: EdgeInsets.all(16.r),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                            color: AppColors.softGold,
                            width: 2,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x33D4AF37),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: QrImageView(
                          data: qrPayload,
                          version: QrVersions.auto,
                          size: qrSize.r,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: AppColors.cinematicNavy,
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: AppColors.cinematicNavy,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 24.h),

                    // Action Buttons Row (Save & Share)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              onSave();
                            },
                            icon: const HugeIcon(
                              icon: HugeIcons.strokeRoundedDownload01,
                              color: AppColors.cinematicNavy,
                            ),
                            label: Text(
                              "save_qr".tr(),
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.bold,
                                color: AppColors.cinematicNavy,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.softGold,
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14.r),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              onShare();
                            },
                            icon: const HugeIcon(
                              icon: HugeIcons.strokeRoundedShare01,
                              color: AppColors.softGold,
                            ),
                            label: Text(
                              "share_qr".tr(),
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.bold,
                                color: AppColors.softGold,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.softGold),
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14.r),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
