import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:test_steps/core/theme/app_text_styles.dart';

class ProfileSettingsTile extends StatelessWidget {
  const ProfileSettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 2.h),
      onTap: onTap,
      leading: Icon(icon, color: const Color(0xFF675FAA), size: 22.sp),
      title: Text(
        title,
        style: AppTextStyles.style(
          fontFamily: 'Poppins',
          size: 14,
          weight: FontWeight.w600,
          color: const Color(0xFF1E293B),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.style(
          fontFamily: 'Inter',
          size: 12,
          color: const Color(0xFF64748B),
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: const Color(0xFF94A3B8),
        size: 20.sp,
      ),
    );
  }
}
