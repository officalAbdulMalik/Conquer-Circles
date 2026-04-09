import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';

class SeasonRecapStatTile extends StatelessWidget {
  const SeasonRecapStatTile({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.backgroundColor,
    required this.valueColor,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color backgroundColor;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(10.w, 8.h, 10.w, 8.h),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 13.sp, color: AppColors.textSecondary),
          5.verticalSpace,
          Text(
            title,
            style: AppTextStyles.inter(
              size: 10,
              color: AppColors.textSecondary,
              weight: FontWeight.w500,
            ),
          ),
          4.verticalSpace,
          Text(
            value,
            style: AppTextStyles.poppins(
              size: 15,
              color: valueColor,
              weight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
