import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:test_steps/core/theme/app_text_styles.dart';

class ProfileAchievementTile extends StatelessWidget {
  const ProfileAchievementTile({
    super.key,
    required this.icon,
    required this.title,
    required this.isCompleted,
  });

  final String icon;
  final String title;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    final baseColor = isCompleted
        ? const Color(0xFFF5F3FF)
        : const Color(0xFFF1F5F9);

    return Stack(
      children: [
        Container(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14.r),
            color: baseColor,
            border: Border.all(
              color: isCompleted
                  ? const Color(0xFFD8CCFF)
                  : const Color(0xFFE5EAF2),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                icon,
                style: AppTextStyles.style(
                  fontFamily: 'Poppins',
                  size: 24,
                  color: isCompleted
                      ? const Color(0xFF675FAA)
                      : const Color(0xFF94A3B8),
                ),
              ),
              6.verticalSpace,
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextStyles.style(
                  fontFamily: 'Inter',
                  size: 10,
                  weight: FontWeight.w600,
                  color: isCompleted
                      ? const Color(0xFF475569)
                      : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
        if (!isCompleted)
          Positioned(
            right: 8.w,
            top: 8.h,
            child: Icon(
              Icons.lock,
              size: 14.sp,
              color: const Color(0xFF94A3B8),
            ),
          ),
      ],
    );
  }
}
