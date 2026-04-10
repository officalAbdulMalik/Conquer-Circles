import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';

class SeasonRecapAchievementTile extends StatelessWidget {
  const SeasonRecapAchievementTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.bgLight,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 24.w,
            height: 24.w,
            decoration: BoxDecoration(
              color: AppColors.primaryLighter,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 12.sp, color: AppColors.brandPurple),
          ),
          8.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 14.sp,
                    color: AppColors.textNavy,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                2.verticalSpace,
                Text(
                  subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontSize: 11.sp,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
