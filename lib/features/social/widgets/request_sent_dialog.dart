import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/widgets/shared/app_borders.dart';

class RequestSentDialog extends StatelessWidget {
  const RequestSentDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 28.w),
      backgroundColor: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          border: AppBorders.raised(),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 55.w,
              height: 55.w,
              decoration: const BoxDecoration(
                color: Color(0xFF24C2AD),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 40.sp,
              ),
            ),
            16.verticalSpace,
            Text(
              'Request Sent',
              textAlign: TextAlign.center,
              style: AppTextStyles.montserrat(
                size: 20.sp,
                color: AppColors.textPrimary,
                weight: FontWeight.w800,
              ),
            ),
            10.verticalSpace,
            Text(
              'You’ve successfully sent request, upon admin approval you’ll get notification to join circle.',
              textAlign: TextAlign.center,
              style: AppTextStyles.montserrat(
                size: 14.sp,
                color: AppColors.textSecondary,
                weight: FontWeight.w500,
               
              ),
            ),
          ],
        ),
      ),
    );
  }
}
