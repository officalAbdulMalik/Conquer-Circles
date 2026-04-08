import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:test_steps/core/theme/app_text_styles.dart';

class StreakCard extends StatelessWidget {
  final int streakDays;

  const StreakCard({super.key, required this.streakDays});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 32.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED), // orange-50
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFFFEDD5)), // orange-100
      ),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.h,
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(8.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withValues(alpha: 0.2),
                  blurRadius: 10.r,
                  offset: Offset(0, 4.h),
                ),
              ],
            ),
            child: Icon(
              Icons.local_fire_department,
              color: Colors.white,
              size: 24.sp,
            ),
          ),
          12.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$streakDays Day Streak!',
                  style: AppTextStyles.style(
                    fontFamily: 'Poppins',
                    color: Color(0xFF7C2D12), // orange-900
                    size: 14,
                    weight: FontWeight.bold,
                  ),
                ),
                Text(
                  "You're on fire this month.",
                  style: AppTextStyles.style(
                    fontFamily: 'Inter',
                    color: const Color(0xFFC2410C).withValues(alpha: 0.7),
                    size: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: Color(0xFFFB923C), // orange-400
            size: 24.sp,
          ),
        ],
      ),
    );
  }
}
