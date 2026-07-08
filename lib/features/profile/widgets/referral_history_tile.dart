import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';

class ReferralHistoryTile extends StatelessWidget {
  const ReferralHistoryTile({
    super.key,
    required this.name,
    required this.time,
    required this.amount,
  });

  final String name;
  final String time;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.montserrat(
                    size: 15.sp,
                    weight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                ),
                4.verticalSpace,
                Text(
                  time,
                  style: AppTextStyles.montserrat(
                    size: 12.sp,
                    color: AppColors.textSecondary,
                    weight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: AppTextStyles.montserrat(
              size: 14.sp,
              weight: FontWeight.w700,
              color: AppColors.blueColor,
            ),
          ),
        ],
      ),
    );
  }
}
