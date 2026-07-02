import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/widgets/shared/app_borders.dart';

class CircleCreatedDialog extends StatelessWidget {
  const CircleCreatedDialog({super.key, this.onClose});

  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 15.w),
      backgroundColor: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 28.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          border: AppBorders.raised(),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Positioned(
              right: 0,
              top: -2.h,
              child: InkWell(
                borderRadius: BorderRadius.circular(18.r),
                onTap: onClose ?? () => Navigator.of(context).pop(),
                child: Padding(
                  padding: EdgeInsets.all(4.w),
                  child: Icon(
                    Icons.close_rounded,
                    size: 24.sp,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56.w,
                  height: 56.w,
                  decoration: const BoxDecoration(
                    color: Color(0xFF24C2AD),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 42.sp,
                  ),
                ),
                18.verticalSpace,
                Text(
                  'Circle Created',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.montserrat(
                    size: 20.sp,
                    color: AppColors.textPrimary,
                    weight: FontWeight.w800,
                  ),
                ),
                14.verticalSpace,
                Text(
                  'You’ve successfuly create circle and\nwill control as admin',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.montserrat(
                    size: 16.sp,
                    color: AppColors.textSecondary,
                    weight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
