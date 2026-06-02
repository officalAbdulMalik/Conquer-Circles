
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/widgets/shared/app_borders.dart';

class ObjectiveTaskCard extends StatelessWidget {
  const ObjectiveTaskCard({
    super.key,
    required this.icon,
    required this.title,
    required this.progressLabel,
    required this.percent,
    required this.iconColor,
    required this.iconBackgroundColor,
    this.onTap,
  });

  final String icon;
  final String title;
  final String progressLabel;
  final double percent;
  final Color iconColor;
  final Color iconBackgroundColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final normalizedPercent = percent.clamp(0.0, 1.0);

    return InkWell(
      borderRadius: BorderRadius.circular(20.r),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 13.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          border: AppBorders.raised(),
        ),
        child: Row(
          children: [
            Container(
             padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: AppColors.borderColor, width: 1.w),
              ),
              child: Center(
                    child: SvgPicture.asset(
                      icon,
                      width: 36.w,
                      height: 36.w,
                      colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                    ),
                  ),
                
              
            ),
            10.horizontalSpace,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.montserrat(
                          size: 16.sp,
                          color: AppColors.textPrimary,
                          weight: FontWeight.w700,
                        ),
                      ),
                      10.horizontalSpace,
                      
                    ],
                  ),
                  5.verticalSpace,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        progressLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.montserrat(
                          size: 14.sp,
                          color: AppColors.textSecondary,
                          weight: FontWeight.w400,
                        ),
                      ),
                      Text(
                        '${(normalizedPercent * 100).round()}%',
                        style: AppTextStyles.montserrat(
                          size: 14.sp,
                          color: AppColors.textPrimary,
                          weight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  8.verticalSpace,
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        children: [
                          Container(
                            width: double.infinity,
                            height: 5.h,
                            decoration: BoxDecoration(
                              color: AppColors.borderColor,
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                          ),
                          Container(
                            width: constraints.maxWidth * normalizedPercent,
                            height: 5.h,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF8C70F8), Color(0xFF53E4F3)],
                              ),
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}