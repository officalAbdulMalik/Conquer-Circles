import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';

class CancelSubscriptionDialog extends StatelessWidget {
  const CancelSubscriptionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
      ),
      title: Text(
        'Cancel Subscription?',
        style: AppTextStyles.montserrat(
          size: 18,
          weight: FontWeight.w700,
          color: AppColors.textNavy,
        ),
      ),
      content: Text(
        'Are you sure you want to cancel your subscription? You will retain access to your premium features until the end of your billing cycle.',
        style: AppTextStyles.montserrat(
          size: 14,
          weight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            'Keep Plan',
            style: AppTextStyles.montserrat(
              size: 14,
              weight: FontWeight.w600,
              color: AppColors.blueColor,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            'Cancel Subscription',
            style: AppTextStyles.montserrat(
              size: 14,
              weight: FontWeight.w600,
              color: AppColors.error,
            ),
          ),
        ),
      ],
    );
  }
}
