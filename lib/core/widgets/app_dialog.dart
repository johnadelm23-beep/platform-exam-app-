import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';

class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    this.icon,
    this.iconWidget,
    this.iconColor = Colors.amber,
    required this.title,
    required this.description,
    required this.confirmText,
    required this.onConfirm,
    this.cancelText,
    this.onCancel,
    this.confirmButtonColor = Colors.green,
    this.customContent,
  });

  final IconData? icon;
  final Widget? iconWidget;
  final Color iconColor;
  final String title;
  final String description;
  final String confirmText;
  final VoidCallback onConfirm;
  final String? cancelText;
  final VoidCallback? onCancel;
  final Color confirmButtonColor;
  final Widget? customContent;

  static void show({
    required BuildContext context,
    IconData? icon,
    Widget? iconWidget,
    Color iconColor = Colors.amber,
    required String title,
    required String description,
    required String confirmText,
    required VoidCallback onConfirm,
    String? cancelText,
    VoidCallback? onCancel,
    Color confirmButtonColor = Colors.green,
    Widget? customContent,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AppDialog(
          icon: icon,
          iconWidget: iconWidget,
          iconColor: iconColor,
          title: title,
          description: description,
          confirmText: confirmText,
          onConfirm: onConfirm,
          cancelText: cancelText,
          onCancel: onCancel,
          confirmButtonColor: confirmButtonColor,
          customContent: customContent,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final titleColor = isDark ? AppColors.darkTextMain : AppColors.lightTextMain;
    final descColor = isDark ? AppColors.darkTextCaption : Colors.grey[700];
    final cancelColor = isDark ? AppColors.darkTextMuted : Colors.grey[700];
    final borderColor = isDark ? AppColors.darkBorder : Colors.grey[300]!;

    return Dialog(
      backgroundColor: dialogBg,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      child: Padding(
        padding: EdgeInsets.all(20.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (iconWidget != null)
              iconWidget!
            else if (icon != null)
              Icon(icon, color: iconColor, size: 60.r),
            SizedBox(height: 15.h),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16.sp, color: descColor),
            ),
            if (customContent != null) ...[
              SizedBox(height: 15.h),
              customContent!,
            ],
            SizedBox(height: 20.h),
            if (cancelText != null)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: borderColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      onPressed: onCancel ?? () => Navigator.pop(context),
                      child: Text(
                        cancelText!,
                        style: TextStyle(
                          fontSize: 15.sp,
                          color: cancelColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: confirmButtonColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      onPressed: onConfirm,
                      child: Text(
                        confirmText,
                        style: TextStyle(
                          fontSize: 15.sp,
                          color: AppColors.whiteColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: confirmButtonColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                  onPressed: onConfirm,
                  child: Text(
                    confirmText,
                    style: TextStyle(
                      fontSize: 15.sp,
                      color: AppColors.whiteColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
