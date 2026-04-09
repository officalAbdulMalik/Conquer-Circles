import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/features/social/models/guild_models.dart';
import 'package:test_steps/widgets/shared/user_avatar.dart';

class MemberAvatarRow extends StatelessWidget {
  const MemberAvatarRow({
    super.key,
    required this.members,
    required this.extraCount,
  });

  final List<GuildMember> members;
  final int extraCount;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...members.map(
            (m) => Padding(
              padding: EdgeInsets.only(right: 8.w),
              child: UserAvatar(
                avatarEmoji: m.avatarEmoji,
                bgColor: m.bgColor,
                isOnline: m.isOnline,
                size: 44,
              ),
            ),
          ),
          // +N bubble
          Container(
            width: 44.r,
            height: 44.r,
            decoration: BoxDecoration(
              color: AppColors.tabActiveBg,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.surface, width: 2.r),
            ),
            child: Center(
              child: Text(
                '+$extraCount',
                style: AppTextStyles.inter(
                  size: 12,
                  color: AppColors.accentPurple,
                  weight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
