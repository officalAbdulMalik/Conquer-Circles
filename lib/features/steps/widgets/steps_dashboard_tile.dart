import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/widgets/shared/app_borders.dart';
import 'package:test_steps/widgets/shared/app_shimmer.dart';

class StepsDashboardTile extends StatelessWidget {
  const StepsDashboardTile({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.iconBackgroundColor,
    this.isLoading = false,
    this.unit,
    this.footer,
    this.footerIcon,
    this.footerIconColor,
    this.onTap,
  });

  final String title;
  final String value;
  final String? unit;
  final String icon;
  final Color iconBackgroundColor;
  final bool isLoading;
  final String? footer;
  final IconData? footerIcon;
  final Color? footerIconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 18.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22.r),
          border: AppBorders.raised(),
          color: Colors.white,
          // boxShadow: [
          //   // BoxShadow(
          //   //   color: const Color(0x140F172A),
          //   //   blurRadius: 10.r,
          //   //   offset: Offset(0, 3.h),
          //   // ),
          // ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 50.w,
              height: 50.w,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(color: AppColors.borderColor, width: 1.w),
              ),
              child: Center(
                child: Container(
                  width: 34.w,
                  height: 34.w,
                  decoration: BoxDecoration(
                    color: iconBackgroundColor,
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(6.w),
                    child: Image.asset(
                      icon,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ),
              ),
            ),
            const Spacer(),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.montserrat(
                size: 15.sp,
                color: AppColors.textPrimary,
                weight: FontWeight.w400,
              ),
            ),
            8.verticalSpace,
            if (isLoading)
              AppShimmerBox(width: 82.w, height: 22.h, borderRadius: 7.r)
            else
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text.rich(
                  TextSpan(
                    text: value,
                    style: AppTextStyles.montserrat(
                      size: 20.sp,
                      color: AppColors.textPrimary,
                      weight: FontWeight.w800,
                      height: 1.1,
                    ),
                    children: [
                      if (unit != null)
                        TextSpan(
                          text: ' $unit',
                          style: AppTextStyles.montserrat(
                            size: 16.sp,
                            color: AppColors.textPrimary,
                            weight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            if (footer != null) ...[
              6.verticalSpace,
              Row(
                children: [
                  if (footerIcon != null) ...[
                    Icon(
                      footerIcon,
                      size: 14.sp,
                      color: footerIconColor ?? const Color(0xFF12B981),
                    ),
                    5.horizontalSpace,
                  ],
                  Expanded(
                    child: Text(
                      footer!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.montserrat(
                        size: 11.sp,
                        color: AppColors.textSecondary,
                        weight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
