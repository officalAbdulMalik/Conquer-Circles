import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/widgets/shared/app_borders.dart';

class DashboardSegmentedTabBar extends StatelessWidget {
  const DashboardSegmentedTabBar({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
    this.height = 46,
    this.backgroundColor = AppColors.surface,
    this.inactiveTextColor = AppColors.textPrimary,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final double height;
  final Color backgroundColor;
  final Color inactiveTextColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height.h,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24.r),
        border: AppBorders.raised(),
      ),
      child: Row(
        children: List.generate(labels.length, (index) {
          return Expanded(
            child: DashboardSegmentedTabButton(
              label: labels[index],
              selected: selectedIndex == index,
              inactiveTextColor: inactiveTextColor,
              onTap: () => onChanged(index),
            ),
          );
        }),
      ),
    );
  }
}

class DashboardSegmentedTabButton extends StatelessWidget {
  const DashboardSegmentedTabButton({
    super.key,
    required this.label,
    required this.selected,
    required this.inactiveTextColor,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color inactiveTextColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.blueColor : Colors.transparent,
      borderRadius: BorderRadius.circular(24.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(24.r),
        onTap: onTap,
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.montserrat(
              size: 14.sp,
              color: selected ? AppColors.surface : inactiveTextColor,
              weight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
