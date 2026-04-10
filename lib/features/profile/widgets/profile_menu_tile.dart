import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';

class ProfileMenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? iconColor;
  final Color? iconBgColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  const ProfileMenuTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconColor,
    this.iconBgColor,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
        child: Row(
          children: [
            Container(
              width: 40.w,
              height: 40.h,
              decoration: BoxDecoration(
                color: iconBgColor ?? AppColors.primaryLighter,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                icon,
                color: iconColor ?? AppColors.primary,
                size: 20.sp,
              ),
            ),
            16.horizontalSpace,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    2.verticalSpace,
                    Text(
                      subtitle!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            trailing ??
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary.withOpacity(0.5),
                  size: 20.sp,
                ),
          ],
        ),
      ),
    );
  }
}
