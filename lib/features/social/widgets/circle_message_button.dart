import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/widgets/shared/app_borders.dart';

class CircleMessageButton extends StatelessWidget {
  const CircleMessageButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      
     decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40.r),
         color: AppColors.blueColor,
         border: AppBorders.raised(),
        // shadowColor: AppColors.blueColor.withValues(alpha: 0.28),
      ),
      // shadowColor: AppColors.blueColor.withValues(alpha: 0.28),
      child: InkWell(
        borderRadius: BorderRadius.circular(40.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 14.h, 20.w, 14.h),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
               padding: EdgeInsets.all(9.sp),
                decoration: BoxDecoration(
                  color: Color(0xffDBEAFE),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Image.asset(
                    'assets/icons/battery.png',
                    width: 18.sp,
                    height: 18.sp,
                  ),
                ),
              ),
              12.horizontalSpace,
              Text(
                'Message',
                style: AppTextStyles.montserrat(
                  size: 16.sp,
                  color: Colors.white,
                  weight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
