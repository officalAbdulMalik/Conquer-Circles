import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/features/leaderboard/models/leaderboard_participant.dart';
import 'package:test_steps/features/leaderboard/widgets/leaderboard_avatar.dart';
import 'package:test_steps/widgets/shared/app_borders.dart';

class LeaderboardParticipantTile extends StatelessWidget {
  const LeaderboardParticipantTile({super.key, required this.participant});

  final LeaderboardParticipant participant;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22.r),
        border: AppBorders.raised(),
      ),
      child: Row(
        children: [
          LeaderboardAvatar(participant: participant, size: 54),
          14.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        participant.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.montserrat(
                          size: 14.sp,
                          color: AppColors.textPrimary,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (participant.isCurrentUser) ...[
                      8.horizontalSpace,
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.currentUserChip,
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Text(
                          'You',
                          style: AppTextStyles.montserrat(
                            size: 12.sp,
                            color: AppColors.green,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                6.verticalSpace,
                Text(
                  '#${participant.rank}',
                  style: AppTextStyles.montserrat(
                    size: 14.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          8.horizontalSpace,
          Text(
            '${participant.score}',
            style: AppTextStyles.montserrat(
              size: 14.sp,
              color: AppColors.textPrimary,
              weight: FontWeight.w700,
            ),
          ),
          7.horizontalSpace,
          Image.asset('assets/icons/battery.png', width: 19.sp, height: 19.sp),
        ],
      ),
    );
  }
}
