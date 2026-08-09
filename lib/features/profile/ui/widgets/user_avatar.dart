import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';

class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final Color? backgroundColor;
  final Color? iconColor;
  final BoxBorder? border;
  final String? heroTag;

  const UserAvatar({
    super.key,
    this.imageUrl,
    this.radius = 28.0,
    this.backgroundColor,
    this.iconColor,
    this.border,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = radius.r;
    final effectiveBgColor =
        backgroundColor ?? AppColors.primaryColor.withValues(alpha: 0.1);
    final effectiveIconColor = iconColor ?? AppColors.primaryColor;

    Widget avatarCore = Container(
      width: effectiveRadius * 2,
      height: effectiveRadius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: effectiveBgColor,
        border: border,
      ),
      child: ClipOval(
        child: (imageUrl != null && imageUrl!.trim().isNotEmpty)
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                width: effectiveRadius * 2,
                height: effectiveRadius * 2,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: SizedBox(
                      width: effectiveRadius * 0.8,
                      height: effectiveRadius * 0.8,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: effectiveIconColor,
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedUser02,
                      size: effectiveRadius * 1.1,
                      color: effectiveIconColor,
                    ),
                  );
                },
              )
            : Center(
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedUser02,
                  size: effectiveRadius * 1.1,
                  color: effectiveIconColor,
                ),
              ),
      ),
    );

    if (heroTag != null && heroTag!.isNotEmpty) {
      return Hero(tag: heroTag!, child: avatarCore);
    }

    return avatarCore;
  }
}
