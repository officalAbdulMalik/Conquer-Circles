import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/widgets/shared/app_borders.dart';

class CircleChatOptionsSheet extends StatelessWidget {
  const CircleChatOptionsSheet({
    super.key,
    this.onBlockChat,
    this.onLeaveCircle,
  });

  final VoidCallback? onBlockChat;
  final VoidCallback? onLeaveCircle;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(15.w, 7.h, 15.w, 24.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 49.w,
              height: 5.h,
              margin: EdgeInsets.only(bottom: 13.h),
              decoration: BoxDecoration(
                color: const Color(0xFFD9DCE4),
                borderRadius: BorderRadius.circular(99.r),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.r),
                border: AppBorders.raised(),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _OptionTile(
                    icon: Icons.block_outlined,
                    label: 'Block Chat',
                    onTap: onBlockChat,
                  ),
                  Divider(height: 1, color: AppColors.borderColor),
                  _OptionTile(
                    icon: Icons.logout_rounded,
                    label: 'Leave Chat',
                    onTap: onLeaveCircle,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const color = AppColors.textPrimary;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        child: Row(
          children: [
            Container(
              width: 54.w,
              height: 54.w,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15.r),
                border: Border.all(color: AppColors.borderColor),
              ),
              child: Icon(icon, size: 25.sp, color: color),
            ),
            12.horizontalSpace,
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.montserrat(
                  size: 15.sp,
                  color: color,
                  weight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
