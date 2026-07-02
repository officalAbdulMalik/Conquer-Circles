import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';

class ProfileMenuRow extends StatelessWidget {
  const ProfileMenuRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
    this.titleColor,
  });

  final String icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.r),
             
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.borderColor, width: 1),
              
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Image.asset(
                icon,
                width: 24.sp,
                height: 24.sp,
                color: titleColor ?? AppColors.textPrimary,
              ),
            ),
            12.horizontalSpace,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.montserrat(
                      size: 14.sp,
                      weight: FontWeight.w600,
                      color: titleColor ?? AppColors.textPrimary,
                    ),
                  ),
                  2.verticalSpace,
                  Text(
                    subtitle,
                    style: AppTextStyles.montserrat(
                      size: 12.sp,
                      color: AppColors.textSecondary,
                      weight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              8.horizontalSpace,
              trailing!,
            ] else ...[
              // 8.horizontalSpace,
              // Icon(
              //   Icons.chevron_right_rounded,
              //   size: 20.r,
              //   color: AppColors.textSecondary,
              // ),
            ],
          ],
        ),
      ),
    );
  }
}
