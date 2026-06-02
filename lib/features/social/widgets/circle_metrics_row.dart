import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/features/social/models/circle_detail_models.dart';
import 'package:test_steps/widgets/shared/app_borders.dart';

class CircleMetricsRow extends StatelessWidget {
  const CircleMetricsRow({super.key, required this.metrics});

  final List<CircleDetailMetric> metrics;

  _showMemeberDailog(BuildContext context) {
    final members = const [
      ('Aqib Javid', '👨🏽', 'Admin'),
      ('Sarah Ahmed', '👩🏼', null),
      ('Micheal Waliam', '🧔🏽', null),
      ('Asim Kamal', '👨🏻', null),
       ('Asim Kamal', '👨🏻', null),
        ('Asim Kamal', '👨🏻', null),
         ('Asim Kamal', '👨🏻', null),
          ('Asim Kamal', '👨🏻', null),
           ('Asim Kamal', '👨🏻', null),
    ];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
           height: 700.h,
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 28.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 49.w,
                    height: 5.h,
                    margin: EdgeInsets.only(bottom: 14.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9DCE4),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20.r),
                    border: AppBorders.raised(),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 60.w,
                        height: 60.w,
                        decoration: BoxDecoration(
                          color: AppColors.blueContiner,
                          borderRadius: BorderRadius.circular(18.r),
                        ),
                        child: Center(
                          child: Image.asset(
                            'assets/icons/battery.png',
                            width: 38.w,
                            height: 38.w,
                          ),
                        ),
                      ),
                      12.verticalSpace,
                      Text(
                        'StromWalker Team',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.montserrat(
                          size: 16.sp,
                          color: AppColors.textPrimary,
                          weight: FontWeight.w700,
                        ),
                      ),
                      6.verticalSpace,
                      Text(
                        '48.2 km² Territory · 14 / 20 Members',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.montserrat(
                          size: 12.sp,
                          color: AppColors.textSecondary,
                          weight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                14.verticalSpace,
                Text(
                  '14 members',
                  style: AppTextStyles.montserrat(
                    size: 14.sp,
                    color: AppColors.textPrimary,
                    weight: FontWeight.w700,
                  ),
                ),
                12.verticalSpace,
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20.r),
                    border: AppBorders.raised(),
                  ),
                  child: Column(
                    children: List.generate(members.length, (index) {
                      final member = members[index];
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
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      member.$2,
                                      style: AppTextStyles.montserrat(
                                        size: 28.sp,
                                        color: AppColors.textPrimary,),
                                    ),
                                  ),
                                ),
                                14.horizontalSpace,
                                Expanded(
                                  child: Text(
                                    member.$1,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.montserrat(
                                      size: 14.sp,
                                      color: AppColors.textPrimary,
                                      weight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (member.$3 != null)
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 14.w,
                                      vertical: 4.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE0EAFF),
                                      borderRadius: BorderRadius.circular(18.r),
                                    ),
                                    child: Text(
                                      member.$3!,
                                      style: AppTextStyles.montserrat(
                                        size: 13.sp,
                                        color: AppColors.blueColor,
                                        weight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (index != members.length - 1)
                            Divider(height: 1, color: AppColors.borderColor),
                        ],
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(metrics.length, (index) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index == metrics.length - 1 ? 0 : 12.w,
            ),
            child: InkWell(
              onTap: () => _showMemeberDailog(context),
              borderRadius: BorderRadius.circular(20.r),
              child: Container(
                height: 148.h,
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20.r),
                  border: AppBorders.raised(),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18.r),
                        border: Border.all(color: AppColors.borderColor),
                      ),
                      child: Image.asset(
                        metrics[index].icon,
                        height: 37.sp,
                        width: 37.sp,
                        fit: BoxFit.cover,
                      ),
                    ),
                    8.verticalSpace,
                    Text(
                      metrics[index].label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.montserrat(
                        size: 14.sp,
                        color: AppColors.textPrimary,
                        weight: FontWeight.w400,
                      ),
                    ),
                    8.verticalSpace,
                    Text(
                      metrics[index].value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.montserrat(
                        size: 16.sp,
                        color: AppColors.textPrimary,
                        weight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
