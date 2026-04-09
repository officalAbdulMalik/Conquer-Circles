import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';

class ProfileStatsRangeSwitch extends StatelessWidget {
  const ProfileStatsRangeSwitch({
    super.key,
    required this.isWeekly,
    required this.onChanged,
  });

  final bool isWeekly;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ProfileStatsRangePill(
            label: 'Weekly',
            active: isWeekly,
            onTap: () => onChanged(true),
          ),
          ProfileStatsRangePill(
            label: 'Monthly',
            active: !isWeekly,
            onTap: () => onChanged(false),
          ),
        ],
      ),
    );
  }
}

class ProfileStatsRangePill extends StatelessWidget {
  const ProfileStatsRangePill({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 9.h),
        decoration: BoxDecoration(
          color: active ? AppColors.brandPurple : Colors.transparent,
          borderRadius: BorderRadius.circular(999.r),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: AppColors.textNavy.withValues(alpha: 0.12),
                    blurRadius: 12.r,
                    offset: Offset(0, 5.h),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: AppTextStyles.poppins(
            size: 15,
            color: active ? AppColors.surface : AppColors.brandPurple,
            weight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
