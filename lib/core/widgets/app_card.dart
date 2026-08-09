import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';
import 'package:platformexamapp/core/widgets/glass_card.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final Color? color;
  final bool isGlass;
  final BorderSide? border;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.color,
    this.isGlass = true,
    this.border,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isGlass) {
      return GlassCard(
        padding: padding,
        borderRadius: borderRadius,
        customBgColor: color,
        onTap: onTap,
        child: child,
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final r = borderRadius ?? 24.r;
    final surfaceColor =
        color ?? (isDark ? AppColors.darkSurface : AppColors.lightSurface);
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    Widget content = Container(
      padding: padding ?? EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(r),
        border: border != null
            ? Border.fromBorderSide(border!)
            : Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: isDark ? const Color(0x66000000) : const Color(0x140F1C3F),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
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
