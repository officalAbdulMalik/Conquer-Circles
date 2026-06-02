import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/features/social/models/circle_detail_models.dart';
import 'package:test_steps/widgets/shared/app_borders.dart';

class CircleLeaderboardList extends StatelessWidget {
  const CircleLeaderboardList({super.key, required this.members});
  final List<CircleLeaderboardMember> members;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(members.length, (index) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: index == members.length - 1 ? 0 : 10.h,
          ),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.r),
              border: AppBorders.raised(),
            ),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 56.w,
                      height: 56.w,
                      decoration: BoxDecoration(
                        color: AppColors.lightBlueColor,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: AppColors.borderColor),
                      ),
                      child: Center(
                        child: Text(
                          members[index].avatar,
                          style: TextStyle(fontSize: 28.sp),
                        ),
                      ),
                    ),
                    if (members[index].medal != null)
                      Positioned(
                        right: -5.w,
                        bottom: -5.h,
                        child: Container(
                          width: 24.w,
                          height: 24.w,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.borderColor),
                          ),
                          child: Center(
                            child: Text(
                              members[index].medal!,
                              style: TextStyle(fontSize: 14.sp),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                14.horizontalSpace,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              members[index].name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.montserrat(
                                size: 14.sp,
                                color: AppColors.textPrimary,
                                weight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (members[index].isCurrentUser) ...[
                            8.horizontalSpace,
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 5.h,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFC9F7EC),
                                borderRadius: BorderRadius.circular(18.r),
                              ),
                              child: Text(
                                'You',
                                style: AppTextStyles.montserrat(
                                  size: 12.sp,
                                  color: AppColors.green,
                                  weight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      6.verticalSpace,
                      Text(
                        members[index].rank,
                        style: AppTextStyles.montserrat(
                          size: 14.sp,
                          color: AppColors.textSecondary,
                          weight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                10.horizontalSpace,
                Text(
                  '${members[index].score}',
                  style: AppTextStyles.montserrat(
                    size: 14.sp,
                    color: AppColors.textPrimary,
                    weight: FontWeight.w700,
                  ),
                ),
                8.horizontalSpace,
                Image.asset(
                  'assets/icons/battery.png',
                  width: 19.sp,
                  height: 19.sp,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
