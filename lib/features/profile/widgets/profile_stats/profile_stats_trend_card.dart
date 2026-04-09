import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/features/profile/widgets/profile_stats/profile_stats_models.dart';

class ProfileStatsTrendCard extends StatelessWidget {
  const ProfileStatsTrendCard({
    super.key,
    required this.values,
    required this.days,
    required this.maxValue,
    required this.metricTitle,
    required this.metric,
  });

  final List<double> values;
  final List<String> days;
  final double maxValue;
  final String metricTitle;
  final ProfileMetricData metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 14.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$metricTitle Trend',
            style: AppTextStyles.poppins(
              size: 32,
              color: AppColors.textNavy,
              weight: FontWeight.w700,
            ),
          ),
          12.verticalSpace,
          SizedBox(
            height: 220.h,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(
                  width: 42.w,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      ProfileStatsAxisLabel(text: formatProfileAxisLabel(maxValue, metric)),
                      ProfileStatsAxisLabel(
                        text: formatProfileAxisLabel(maxValue * 0.75, metric),
                      ),
                      ProfileStatsAxisLabel(
                        text: formatProfileAxisLabel(maxValue * 0.5, metric),
                      ),
                      ProfileStatsAxisLabel(
                        text: formatProfileAxisLabel(maxValue * 0.25, metric),
                      ),
                      ProfileStatsAxisLabel(text: formatProfileAxisLabel(0, metric)),
                    ],
                  ),
                ),
                8.horizontalSpace,
                Expanded(
                  child: Row(
                    children: List.generate(values.length, (index) {
                      final value = values[index];
                      final barHeight = ((value / maxValue) * 148).h;
                      return Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              width: 24.w,
                              height: barHeight,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10.r),
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    AppColors.brandPurple.withValues(alpha: 0.45),
                                    AppColors.brandPurple,
                                  ],
                                ),
                              ),
                            ),
                            8.verticalSpace,
                            Text(
                              days[index],
                              style: AppTextStyles.inter(
                                size: 13,
                                color: AppColors.textSecondary,
                                weight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
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

class ProfileStatsAxisLabel extends StatelessWidget {
  const ProfileStatsAxisLabel({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.inter(
        size: 10,
        color: AppColors.textSecondary,
      ),
    );
  }
}
