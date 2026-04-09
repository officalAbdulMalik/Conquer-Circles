import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/features/profile/widgets/profile_stats/profile_stats_models.dart';

class ProfileStatsTabs extends StatelessWidget {
  const ProfileStatsTabs({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  final List<ProfileTopStatTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final item = tabs[index];
          final active = index == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTabSelected(index),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 4.w),
                decoration: BoxDecoration(
                  color: active ? AppColors.background : Colors.transparent,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Column(
                  children: [
                    Icon(
                      item.icon,
                      size: 18.sp,
                      color: active ? AppColors.brandPurple : AppColors.textSecondary,
                    ),
                    4.verticalSpace,
                    Text(
                      item.label,
                      style: AppTextStyles.inter(
                        size: 12,
                        color: active ? AppColors.brandPurple : AppColors.textSecondary,
                        weight: active ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
