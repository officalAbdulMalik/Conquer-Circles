import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/features/social/models/circle_detail_models.dart';
import 'package:test_steps/widgets/shared/app_borders.dart';

class CircleActivityList extends StatelessWidget {
  const CircleActivityList({super.key, required this.items});
  final List<CircleActivityItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: AppBorders.raised(),
      ),
      child: Column(
        children: List.generate(items.length, (index) {
          return Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 12.h),
                child: Row(
                  children: [
                    Container(
                      width: 56.w,
                      height: 56.w,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: AppColors.borderColor,
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: SvgPicture.asset(
                          'assets/icons/dashboard_trophy_icon.svg',
                          width: 37.8.w,
                          height: 37.8.h,
                        ),
                      ),
                    ),
                    14.horizontalSpace,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            items[index].title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.montserrat(
                              size: 14.sp,
                              color: AppColors.textPrimary,
                              weight: FontWeight.w600,
                            ),
                          ),
                          8.verticalSpace,
                          Text(
                            items[index].subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.montserrat(
                              size: 12.sp,
                              color: AppColors.textSecondary,
                              weight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (index != items.length - 1) ...[
                6.verticalSpace,
                Divider(height: 1, color: AppColors.borderColor),
                6.verticalSpace,
              ],
            ],
          );
        }),
      ),
    );
  }
}
