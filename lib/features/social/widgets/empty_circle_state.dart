import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';

class EmptyCircleState extends StatelessWidget {
  const EmptyCircleState({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 64.h),
      child: Center(
        child: Text(
          'No circles found',
          style: AppTextStyles.montserrat(
            size: 14.sp,
            color: AppColors.textSecondary,
            weight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
