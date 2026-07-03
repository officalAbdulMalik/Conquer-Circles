import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';

class PaymentHistoryCard extends StatelessWidget {
  const PaymentHistoryCard({
    super.key,
    required this.appId,
    required this.planName,
    required this.date,
    required this.amount,
  });

  final String appId;
  final String planName;
  final String date;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: AppColors.borderColor,
          width: 1.w,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  appId,
                  style: AppTextStyles.montserrat(
                    size: 12,
                    weight: FontWeight.w500,
                    color: AppColors.textLight,
                  ),
                ),
                4.verticalSpace,
                Text(
                  planName,
                  style: AppTextStyles.montserrat(
                    size: 15,
                    weight: FontWeight.w700,
                    color: AppColors.textNavy,
                  ),
                ),
                4.verticalSpace,
                Text(
                  date,
                  style: AppTextStyles.montserrat(
                    size: 12,
                    weight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: AppTextStyles.montserrat(
              size: 15,
              weight: FontWeight.w700,
              color: AppColors.blueColor,
            ),
          ),
        ],
      ),
    );
  }
}
