import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final Color? customBgColor;
  final Color? customBorderColor;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.customBgColor,
    this.customBorderColor,
    this.onTap,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final r = borderRadius ?? 24.r;
    final defaultBg = isDark
        ? AppColors.darkGlassSurface
        : AppColors.lightGlassSurface;
    final defaultBorder = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final shadowColor = isDark
        ? const Color(0x66000000)
        : const Color(0x140F1C3F);

    Widget content = ClipRRect(
      borderRadius: BorderRadius.circular(r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: width,
          height: height,
          padding: padding ?? EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: customBgColor ?? defaultBg,
            borderRadius: BorderRadius.circular(r),
            border: Border.all(
              color: customBorderColor ?? defaultBorder,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(r),
        child: content,
      );
    }

    return content;
  }
}
