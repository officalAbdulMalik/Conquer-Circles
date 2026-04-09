import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/features/profile/widgets/profile_stats/profile_stats_models.dart';

class ProfileStatsBreakdownCard extends StatelessWidget {
  const ProfileStatsBreakdownCard({
    super.key,
    required this.values,
    required this.maxValue,
    required this.days,
    required this.metric,
  });

  final List<double> values;
  final double maxValue;
  final List<String> days;
  final ProfileMetricData metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Breakdown',
            style: AppTextStyles.poppins(
              size: 32,
              color: AppColors.textNavy,
              weight: FontWeight.w700,
            ),
          ),
          12.verticalSpace,
          ...List.generate(values.length, (index) {
            final value = values[index];
            return Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: Row(
                children: [
                  SizedBox(
                    width: 34.w,
                    child: Text(
                      days[index],
                      style: AppTextStyles.inter(
                        size: 13,
                        color: AppColors.textSecondary,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ),
                  10.horizontalSpace,
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999.r),
                      child: Container(
                        height: 24.h,
                        color: AppColors.background,
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: (value / maxValue).clamp(0.0, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.brandPurple,
                                  AppColors.brandPurple.withValues(alpha: 0.55),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  10.horizontalSpace,
                  SizedBox(
                    width: 58.w,
                    child: Text(
                      formatProfileMetricValue(value, metric),
                      textAlign: TextAlign.right,
                      style: AppTextStyles.poppins(
                        size: 14,
                        color: AppColors.textPrimary,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
