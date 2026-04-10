import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';

class SeasonRecapSummaryCard extends StatelessWidget {
  const SeasonRecapSummaryCard({
    super.key,
    required this.territories,
    required this.rankLabel,
    required this.scoreLabel,
    required this.rewardsUnlocked,
  });

  final int territories;
  final String rankLabel;
  final String scoreLabel;
  final int rewardsUnlocked;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag_outlined, size: 13.sp, color: AppColors.brandPurple),
              6.horizontalSpace,
              Text(
                'Season Summary',
                style: AppTextStyles.heading3,
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.primaryLighter,
                  borderRadius: BorderRadius.circular(999.r),
                ),
                child: Text(
                  '$rewardsUnlocked rewards',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 10.sp,
                  )
                ),
              ),
            ],
          ),
          10.verticalSpace,
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: AppColors.bgLight,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        territories.toString(),
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontSize: 18.sp,
                          color: AppColors.brandPurple,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Territories',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 9.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              8.horizontalSpace,
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: AppColors.bgLight,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rankLabel,
                        style: AppTextStyles.poppins(
                          size: 18,
                          color: AppColors.brandPurple,
                          weight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Season Rank',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 9.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              8.horizontalSpace,
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: AppColors.bgLight,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        scoreLabel,
                        style: AppTextStyles.poppins(
                          size: 18,
                          color: AppColors.brandCyan,
                          weight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Score',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 9.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
