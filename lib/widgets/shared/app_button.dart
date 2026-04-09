import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';

enum AppButtonVariant { filled, outlined }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.filled,
    this.backgroundColor = AppColors.brandPurple,
    this.foregroundColor = AppColors.surface,
    this.borderColor = AppColors.divider,
    this.height = 44,
    this.borderRadius = 12,
    this.horizontalPadding = 14,
    this.textStyle,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;
  final double height;
  final double borderRadius;
  final double horizontalPadding;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final bool isFilled = variant == AppButtonVariant.filled;
    return SizedBox(
      height: height.h,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: isFilled ? backgroundColor : Colors.transparent,
          foregroundColor: isFilled ? foregroundColor : backgroundColor,
          side: isFilled ? null : BorderSide(color: borderColor, width: 1.w),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius.r),
          ),
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding.w),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16.sp),
              6.horizontalSpace,
            ],
            Text(
              label,
              style: (textStyle ?? AppTextStyles.buttonLabel).copyWith(
                color: isFilled ? foregroundColor : backgroundColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppActionTileButton extends StatelessWidget {
  const AppActionTileButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.color = AppColors.brandPrimary,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 18.h),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.28),
              blurRadius: 12.r,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.surface, size: 28.sp),
            8.verticalSpace,
            Text(
              label,
              style: AppTextStyles.poppins(
                size: 14,
                color: AppColors.surface,
                weight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
