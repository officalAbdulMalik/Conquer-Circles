import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/widgets/shared/app_bar_icon_tile.dart';

class DashboardScreenHeader extends StatelessWidget {
  const DashboardScreenHeader({
    super.key,
    required this.title,
    required this.energy,
    required this.onNotificationsTap,
    required this.onProfileTap,
  });

  final String title;
  final int energy;
  final VoidCallback onNotificationsTap;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.montserrat(
              size: 18.sp,
              color: const Color(0xFF111827),
              weight: FontWeight.w700,
            ),
          ),
        ),
        DashboardIconButton(
          icon: 'assets/icons/notification.png',
          onTap: onNotificationsTap,
        ),
        8.horizontalSpace,
        DashboardIconButton(
          icon: 'assets/icons/profile.png',
          onTap: onProfileTap,
        ),
        10.horizontalSpace,
        Container(
          padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 9.sp),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(color: AppColors.borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$energy',
                style: AppTextStyles.montserrat(
                  size: 14.sp,
                  color: const Color(0xFF111827),
                  weight: FontWeight.w700,
                ),
              ),
              6.horizontalSpace,
              Image.asset(
                'assets/icons/battery.png',
                width: 22.sp,
                height: 22.sp,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
