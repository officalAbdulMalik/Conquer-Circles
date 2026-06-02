import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';

class CreateCircleButton extends StatelessWidget {
  const CreateCircleButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.blueColor,
      borderRadius: BorderRadius.circular(28.r),
      elevation: 8,
      shadowColor: AppColors.blueColor.withValues(alpha: 0.28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, color: Colors.white, size: 20.sp),
              8.horizontalSpace,
              Text(
                'Create Circle',
                style: AppTextStyles.montserrat(
                  size: 16.sp,
                  color: Colors.white,
                  weight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
