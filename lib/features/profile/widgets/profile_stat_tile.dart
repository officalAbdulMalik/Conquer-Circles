import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:test_steps/core/theme/app_text_styles.dart';

class ProfileStatTile extends StatelessWidget {
  const ProfileStatTile({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.gradient,
    required this.iconBackground,
  });

  final String icon;
  final String value;
  final String label;
  final List<Color> gradient;
  final Color iconBackground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(8.w, 12.h, 8.w, 12.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18.r),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradient,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0x1A675FAA),
            blurRadius: 16.r,
            offset: Offset(0, 6.h),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 34.w,
            height: 34.h,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(11.r),
            ),
            alignment: Alignment.center,
            child: Text(
              icon,
              style: AppTextStyles.style(
                fontFamily: 'Poppins',
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
          8.verticalSpace,
          Text(
            value,
            textAlign: TextAlign.center,
            style: AppTextStyles.style(
              fontFamily: 'Poppins',
              size: 18,
              weight: FontWeight.w700,
              color: const Color(0xFF1E293B),
              height: 1,
            ),
          ),
          6.verticalSpace,
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.style(
              fontFamily: 'Inter',
              size: 11,
              color: const Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }
}
