import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/widgets/shared/app_borders.dart';

class EnergyUsageTile extends StatelessWidget {
  const EnergyUsageTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
    this.amountColor,
  });

  final String title;
  final String subtitle;
  final String amount;
  final Color? amountColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: AppBorders.raised(),
      ),
      child: Row(
        children: [
          Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              color: AppColors.lightBlueColor,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Center(
              child: Image.asset(
               'assets/icons/power.png',
                width: 24.w,
                height: 24.w,
              ),
            ),
          ),
          12.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.montserrat(
                    size: 16.sp,
                    weight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                6.verticalSpace,
                Text(
                  subtitle,
                  style: AppTextStyles.montserrat(
                    size: 12.sp,
                    color: AppColors.textSecondary,
                    weight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          12.horizontalSpace,
          Text(
            amount,
            style: AppTextStyles.montserrat(
              size: 14.sp,
              weight: FontWeight.w700,
              color: amountColor ?? AppColors.blueColor,
            ),
          ),
        ],
      ),
    );
  }
}
