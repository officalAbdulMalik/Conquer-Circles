import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';

class DashboardIconButton extends StatelessWidget {
  const DashboardIconButton({
    super.key,
    required this.icon,
    required this.onTap,
  });

  final String icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(9.sp),
        width: 42.w,
        height: 42.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: AppColors.borderColor),
          boxShadow: [
            BoxShadow(
              color: const Color(0x140F172A),
              blurRadius: 10.r,
              offset: Offset(0, 3.h),
            ),
          ],
        ),
        child: Image.asset(icon, color: const Color(0xFF0F172A)),
      ),
    );
  }
}
