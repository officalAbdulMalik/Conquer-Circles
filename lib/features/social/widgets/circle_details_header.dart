import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/widgets/shared/app_avatar_stack.dart';
import 'package:test_steps/widgets/shared/app_borders.dart';

class CircleDetailsHeader extends StatelessWidget {
  const CircleDetailsHeader({
    super.key,
    required this.name,
    required this.status,
    required this.onBack,
  });

  final String name;
  final String status;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          customBorder: const CircleBorder(),
          onTap: onBack,
          child: Container(
            width: 38.w,
            height: 38.w,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: AppBorders.raised(),
            ),
            child: Icon(
              Icons.arrow_back_rounded,
              size: 20.sp,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        10.horizontalSpace,
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: AppColors.blueContiner,
            borderRadius: BorderRadius.circular(18.r),
          ),
          child: Center(
            child: Image.asset(
              'assets/icons/battery.png',
              width: 32.sp,
              height: 32.sp,
            ),
          ),
        ),
        10.horizontalSpace,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              2.verticalSpace,
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.montserrat(
                  size: 16.sp,
                  color: AppColors.textPrimary,
                  weight: FontWeight.w700,
                ),
              ),
              6.verticalSpace,
               AppAvatarStack(
                emojis: ['👩', '👱', '🧑', '👨'],
                size: 25.sp,
                overlap: 15,
                backgroundColor: AppColors.surface,
              ),
            ],
          ),
        ),
        10.horizontalSpace,
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: const Color(0xFFC9F7EC),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Text(
            status,
            style: AppTextStyles.montserrat(
              size: 13.sp,
              color: AppColors.green,
              weight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
