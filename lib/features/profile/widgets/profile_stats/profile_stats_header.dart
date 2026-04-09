import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';

class ProfileStatsHeader extends StatelessWidget {
  const ProfileStatsHeader({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180.h,
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 14.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.brandPurple, AppColors.brandCyan],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28.r),
          bottomRight: Radius.circular(28.r),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surface.withValues(alpha: 0.2),
                ),
                child: IconButton(
                  onPressed: onBack,
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18.sp,
                    color: AppColors.surface,
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(width: 42.w),
            ],
          ),
          4.verticalSpace,
          Text(
            'Activity Details',
            style: AppTextStyles.poppins(
              size: 31,
              color: AppColors.surface,
              weight: FontWeight.w700,
            ),
          ),
          4.verticalSpace,
          Text(
            'Track your progress over time',
            style: AppTextStyles.inter(
              size: 16,
              color: AppColors.surface.withValues(alpha: 0.8),
              weight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
