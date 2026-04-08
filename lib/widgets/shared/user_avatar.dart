import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.avatarEmoji,
    required this.bgColor,
    this.size = 40,
    this.isOnline,
    this.badgeEmoji,
    this.showBorder = true,
    this.borderWidth = 2.0,
    this.borderColor = AppColors.surface,
    this.onTap,
  });

  final String avatarEmoji;
  final Color bgColor;
  final double size;
  final bool? isOnline;
  final String? badgeEmoji;
  final bool showBorder;
  final double borderWidth;
  final Color borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final avatarSize = size.r;
    final dotSize = (size * 0.275).r;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── Main Avatar Container ─────────────────────────────────────────
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
              border: showBorder
                  ? Border.all(color: borderColor, width: borderWidth.r)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Text(
                avatarEmoji,
                style: TextStyle(fontSize: (size * 0.45).r),
              ),
            ),
          ),

          // ── Online Status Indicator ───────────────────────────────────────
          if (isOnline != null)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: dotSize,
                height: dotSize,
                decoration: BoxDecoration(
                  color: isOnline!
                      ? AppColors.success
                      : AppColors.textSecondary.withOpacity(0.4),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: borderColor,
                    width: (borderWidth * 0.8).r,
                  ),
                ),
              ),
            ),

          // ── Badge Overlay (e.g. Crown) ────────────────────────────────────
          if (badgeEmoji != null)
            Positioned(
              top: -(size * 0.15).r,
              right: -(size * 0.15).r,
              child: Text(
                badgeEmoji!,
                style: TextStyle(fontSize: (size * 0.35).r),
              ),
            ),
        ],
      ),
    );
  }
}
