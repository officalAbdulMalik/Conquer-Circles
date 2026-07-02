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
    this.height = 38,
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
    final radius = BorderRadius.circular(22.r);

    return Container(
      height: height.h,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: radius,
        border: AppBorders.raised(),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: List.generate(labels.length, (index) {
          return Expanded(
            child: DashboardSegmentedTabButton(
              label: labels[index],
              selected: selectedIndex == index,
              inactiveTextColor: inactiveTextColor,
              index: index,
              itemCount: labels.length,
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
    required this.index,
    required this.itemCount,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color inactiveTextColor;
  final int index;
  final int itemCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selectedRadius = _selectedBorderRadius();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: selected ? AppColors.blueColor : Colors.transparent,
        borderRadius: selectedRadius,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: selectedRadius,
        child: InkWell(
          borderRadius: selectedRadius,
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
      ),
    );
  }

  BorderRadius _selectedBorderRadius() {
    final radius = Radius.circular(22.r);

    if (itemCount <= 1) {
      return BorderRadius.all(radius);
    }

    if (index == 0) {
      return BorderRadius.only(topLeft: radius, bottomLeft: radius);
    }

    if (index == itemCount - 1) {
      return BorderRadius.only(topRight: radius, bottomRight: radius);
    }

    return BorderRadius.zero;
  }
}
