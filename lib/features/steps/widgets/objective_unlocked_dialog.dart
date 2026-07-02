import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/widgets/shared/app_borders.dart';
import 'package:test_steps/widgets/shared/app_button.dart';

class ObjectiveUnlockedDialog extends StatelessWidget {
  const ObjectiveUnlockedDialog({super.key, this.onViewMap});

  final VoidCallback? onViewMap;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 15.w),
      backgroundColor: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          border: AppBorders.raised(),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'NEW OBJECTIVE UNLOCKED',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.montserrat(
                      size: 14.sp,
                      color: AppColors.textPrimary,
                      weight: FontWeight.w800,
                    ),
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(18.r),
                  onTap: () => Navigator.of(context).pop(),
                  child: Padding(
                    padding: EdgeInsets.all(4.w),
                    child: Icon(
                      Icons.close_rounded,
                      size: 24.sp,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            10.verticalSpace,
            Container(
              width: double.infinity,
              height: 130.h,
              decoration: BoxDecoration(
                color: const Color(0xFFDDEBFF),
                borderRadius: BorderRadius.circular(16.r),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/back.png',
                      fit: BoxFit.cover,
                      opacity: const AlwaysStoppedAnimation(0.58),
                    ),
                  ),
                  Container(
                    width: 51.w,
                    height: 51.w,
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Image.asset('assets/images/battery.png'),
                  ),
                ],
              ),
            ),
            16.verticalSpace,
            Text(
              'Expand Your Territory',
              textAlign: TextAlign.center,
              style: AppTextStyles.montserrat(
                size: 20.sp,
                color: AppColors.textPrimary,
                weight: FontWeight.w800,
              ),
            ),
            10.verticalSpace,
            Text(
              'Capture 5 new tiles today to strengthen\nyour control and earn bonus XP\nrewards. Rival activity is increasing\nnearby.',
              textAlign: TextAlign.center,
              style: AppTextStyles.montserrat(
                size: 16.sp,
                color: AppColors.textSecondary,
                weight: FontWeight.w400,
              ),
            ),
            16.verticalSpace,
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18.r),
                border: AppBorders.raised(),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(9.sp),
                    width: 50.w,
                    height: 50.w,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: AppColors.borderColor),
                    ),
                    child: Image.asset('assets/images/battery.png'),
                  ),
                  12.horizontalSpace,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Attach Energy',

                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.montserrat(
                            size: 14.sp,
                            color: AppColors.textPrimary,
                            weight: FontWeight.w400,
                          ),
                        ),
                        5.verticalSpace,
                        Text(
                          '30+',
                          style: AppTextStyles.montserrat(
                            size: 20.sp,
                            color: AppColors.textPrimary,
                            weight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            24.verticalSpace,
            AppOutlinedButton(
              label: 'View Map',
              onPressed: onViewMap ?? () => Navigator.of(context).pop(),
            ),
            10.verticalSpace,
          ],
        ),
      ),
    );
  }
}
