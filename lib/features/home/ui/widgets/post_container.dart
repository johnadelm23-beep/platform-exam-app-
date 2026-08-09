import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:platformexamapp/core/theme/app_colors.dart';
import 'package:platformexamapp/core/widgets/glass_card.dart';
import 'package:platformexamapp/features/auth/data/models/user_data.dart';

class PostContainer extends StatelessWidget {
  const PostContainer({
    super.key,
    required this.isArabic,
    required this.isLiked,
    required this.text,
    required this.user,
    required this.uid,
    required this.likeCount,
    required this.post,
  });

  final bool isArabic;
  final bool isLiked;
  final String text;
  final UserData user;
  final String uid;
  final int likeCount;
  final QueryDocumentSnapshot<Object?> post;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextMain : AppColors.lightTextMain;
    final mutedColor = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: GlassCard(
        padding: EdgeInsets.all(16.r),
        borderRadius: 20.r,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔹 TEXT + DELETE
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: AppColors.softGold.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedMegaphone01,
                    color: AppColors.softGold,
                    size: 20.r,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(top: 2.h),
                    child: Text(
                      text,
                      style: GoogleFonts.cairo(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        height: 1.6,
                        color: textColor,
                      ),
                    ),
                  ),
                ),
                if (user.isAdmin == true)
                  IconButton(
                    icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedDelete01,
                      color: AppColors.softRed,
                    ),
                    onPressed: () => _showDeleteDialog(context),
                  ),
              ],
            ),

            SizedBox(height: 14.h),
            Divider(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
            SizedBox(height: 8.h),

            Row(
              children: [
                GestureDetector(
                  onTap: () async {
                    final ref = FirebaseFirestore.instance
                        .collection("posts")
                        .doc(post.id);

                    if (isLiked) {
                      await ref.update({"likes.$uid": FieldValue.delete()});
                    } else {
                      await ref.update({"likes.$uid": true});
                    }
                  },
                  child: Row(
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedFavourite,
                        color: isLiked ? AppColors.heartRed : mutedColor,
                        size: 20.r,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        "like".tr(),
                        style: GoogleFonts.cairo(
                          fontSize: 13.sp,
                          color: isLiked ? AppColors.heartRed : mutedColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 16.w),
                Text(
                  "likes_count".tr(args: [likeCount.toString()]),
                  style: GoogleFonts.cairo(fontSize: 13.sp, color: mutedColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textColor = isDark ? AppColors.darkTextMain : AppColors.lightTextMain;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: dialogBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
          side: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(20.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: AppColors.heartRed.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.delete_forever_rounded,
                  color: AppColors.heartRed,
                  size: 36.r,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                "delete_post".tr(),
                style: GoogleFonts.cairo(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                "delete_post_confirm".tr(),
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: 14.sp,
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextMuted,
                ),
              ),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        "cancel".tr(),
                        style: GoogleFonts.cairo(
                          fontSize: 16.sp,
                          color: textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.heartRed,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      onPressed: () => _deletePost(context),
                      child: Text(
                        "delete".tr(),
                        style: GoogleFonts.cairo(
                          fontSize: 16.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
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
    );
  }

  Future<void> _deletePost(BuildContext context) async {
    Navigator.pop(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      messenger.showSnackBar(
        SnackBar(
          content: Text("deleting_post".tr(), style: GoogleFonts.cairo()),
          duration: const Duration(seconds: 1),
        ),
      );
      await FirebaseFirestore.instance
          .collection("posts")
          .doc(post.id)
          .delete();
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              "post_deleted_success".tr(),
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: AppColors.successGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text("post_deleted_fail".tr(), style: GoogleFonts.cairo()),
            backgroundColor: AppColors.heartRed,
          ),
        );
      }
    }
  }
}
