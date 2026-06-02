import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/widgets/shared/app_borders.dart';

class StepsDashboardTile extends StatelessWidget {
  const StepsDashboardTile({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.iconBackgroundColor,
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
  final Color iconColor;
  final Color iconBackgroundColor;
  final String? footer;
  final IconData? footerIcon;
  final Color? footerIconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.sp, horizontal: 12.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18.r),
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
                borderRadius: BorderRadius.circular(16.r),
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
                  child: SvgPicture.asset(
                    icon,
                    colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                    width: 18.w,
                    height: 18.w,
                  ),
                ),
              ),
            ),
            //
            12.verticalSpace,
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.montserrat(
                size: 14.sp,
                color: AppColors.textPrimary,
                weight: FontWeight.w400,
              ),
            ),
            8.verticalSpace,
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
              8.verticalSpace,
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
                        size: 12.sp,
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
