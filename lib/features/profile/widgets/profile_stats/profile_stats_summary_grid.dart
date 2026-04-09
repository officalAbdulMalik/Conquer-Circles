import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';

class ProfileStatsSummaryGrid extends StatelessWidget {
  const ProfileStatsSummaryGrid({
    super.key,
    required this.averageValue,
    required this.peakValue,
    required this.totalValue,
    required this.unit,
    required this.changePercent,
  });

  final String averageValue;
  final String peakValue;
  final String totalValue;
  final String unit;
  final int changePercent;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ProfileStatsSummaryTile(
                title: 'Daily Avg',
                value: averageValue,
                subtitle: unit,
              ),
            ),
            10.horizontalSpace,
            Expanded(
              child: ProfileStatsSummaryTile(
                title: 'vs Last Period',
                value: '+$changePercent%',
                subtitle: 'improvement',
                valueColor: AppColors.green,
                prefixIcon: Icons.trending_up_rounded,
              ),
            ),
          ],
        ),
        10.verticalSpace,
        Row(
          children: [
            Expanded(
              child: ProfileStatsSummaryTile(
                title: 'Peak',
                value: peakValue,
                subtitle: unit,
              ),
            ),
            10.horizontalSpace,
            Expanded(
              child: ProfileStatsSummaryTile(
                title: 'Total',
                value: totalValue,
                subtitle: unit,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class ProfileStatsSummaryTile extends StatelessWidget {
  const ProfileStatsSummaryTile({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    this.valueColor,
    this.prefixIcon,
  });

  final String title;
  final String value;
  final String subtitle;
  final Color? valueColor;
  final IconData? prefixIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.inter(
              size: 13,
              color: AppColors.textSecondary,
              weight: FontWeight.w500,
            ),
          ),
          8.verticalSpace,
          Row(
            children: [
              if (prefixIcon != null) ...[
                Icon(prefixIcon, size: 18.sp, color: valueColor ?? AppColors.textNavy),
                4.horizontalSpace,
              ],
              Text(
                value,
                style: AppTextStyles.poppins(
                  size: 36,
                  color: valueColor ?? AppColors.textNavy,
                  weight: FontWeight.w700,
                ),
              ),
            ],
          ),
          4.verticalSpace,
          Text(
            subtitle,
            style: AppTextStyles.inter(
              size: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
