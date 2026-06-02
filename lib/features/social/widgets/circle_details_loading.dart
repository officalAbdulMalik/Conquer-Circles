import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';

class CircleDetailsLoading extends StatelessWidget {
  const CircleDetailsLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 52.h,
          decoration: BoxDecoration(
            color: AppColors.borderLight.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(20.r),
          ),
        ),
        24.verticalSpace,
        Row(
          children: List.generate(3, (index) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: index == 2 ? 0 : 12.w),
                child: Container(
                  height: 138.h,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                ),
              ),
            );
          }),
        ),
        24.verticalSpace,
        Container(
          height: 320.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
          ),
        ),
      ],
    );
  }
}
