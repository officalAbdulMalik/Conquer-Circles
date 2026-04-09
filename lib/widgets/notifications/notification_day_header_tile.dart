import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';

class NotificationDayHeaderTile extends StatelessWidget {
  const NotificationDayHeaderTile({
    super.key,
    required this.label,
    required this.itemCount,
  });

  final String label;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 10.h, bottom: 10.h),
      child: Row(
        children: [
          Text(
            label,
            style: AppTextStyles.cardTitle.copyWith(
              fontSize: 14.sp,
              color: AppColors.textNavy,
            ),
          ),
          SizedBox(width: 8.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
            decoration: BoxDecoration(
              color: AppColors.brandPurple.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999.r),
            ),
            child: Text(
              '$itemCount',
              style: AppTextStyles.chipLabel.copyWith(
                color: AppColors.brandPurple,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
