import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/widgets/shared/app_circular_back_button.dart';

class PlanPurchaseHeader extends StatelessWidget {
  const PlanPurchaseHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const AppCircularBackButton(),
          Expanded(
            child: Text(
              'Plan & Purchase',
              textAlign: TextAlign.center,
              style: AppTextStyles.screenTitle,
            ),
          ),
          // Empty balanced space matching the back button width
          SizedBox(width: 34.w),
        ],
      ),
    );
  }
}
