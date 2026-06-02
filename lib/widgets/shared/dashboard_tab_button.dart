import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/widgets/shared/app_borders.dart';

class DashboardTabButton extends StatelessWidget {
  const DashboardTabButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
  });

  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.blueColor : Colors.white,
      borderRadius: BorderRadius.circular(24.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(24.r),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 12.sp),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24.r),
            border: AppBorders.raised(),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTextStyles.montserrat(
                  size: 13.sp,
                  color: selected ? Colors.white : const Color(0xFF111827),
                  weight: FontWeight.w500,
                ),
              ),
              if (count != null) ...[
                8.horizontalSpace,
                CircleAvatar(
                  radius: 10.r,
                  backgroundColor: const Color(0xFFF4F7FF),
                  child: Text(
                    '$count',
                    style: AppTextStyles.montserrat(
                      size: 11.sp,
                      color: AppColors.blueColor,
                      weight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
