import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/constants/app_emojis.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/widgets/shared/user_avatar.dart';

class CirclesHeader extends StatelessWidget {
  const CirclesHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Circle',
              style: AppTextStyles.screenTitle,
            ),
            SizedBox(height: 4.h),
            Text(
              'Manage your team & rankings',
              style: AppTextStyles.cardSubtitle.copyWith(fontSize: 12.sp),
            ),
          ],
        ),

        UserAvatar(
          avatarEmoji: AppEmojis.eagle,
          bgColor: AppColors.tabActiveBg,
          size: 44,
          showBorder: true,
          borderColor: AppColors.surface,
          borderWidth: 2,
        ),
      ],
    );
  }
}
