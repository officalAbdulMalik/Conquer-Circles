import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/features/leaderboard/models/leaderboard_participant.dart';
import 'package:test_steps/features/leaderboard/widgets/leaderboard_avatar.dart';
import 'package:test_steps/widgets/shared/app_borders.dart';

class LeaderboardPodiumCard extends StatelessWidget {
  const LeaderboardPodiumCard({super.key, required this.participants});

  final List<LeaderboardParticipant> participants;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22.r),
        border: AppBorders.raised(),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: LeaderboardPodiumMember(participant: participants[1]),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: 30.h),
              child: LeaderboardPodiumMember(participant: participants[0]),
            ),
          ),
          Expanded(
            child: LeaderboardPodiumMember(participant: participants[2]),
          ),
        ],
      ),
    );
  }
}

class LeaderboardPodiumMember extends StatelessWidget {
  const LeaderboardPodiumMember({super.key, required this.participant});

  final LeaderboardParticipant participant;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LeaderboardAvatar(participant: participant, size: 58),
        12.verticalSpace,
        Text(
          participant.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.montserrat(
            size: 14.sp,
            color: AppColors.textPrimary,
            weight: FontWeight.w700,
          ),
        ),
        8.verticalSpace,
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${participant.score}',
              style: AppTextStyles.montserrat(
                size: 14.sp,
                color: AppColors.textPrimary,
                weight: FontWeight.w700,
              ),
            ),
            7.horizontalSpace,
            Image.asset(
              'assets/icons/battery.png',
              width: 19.sp,
              height: 19.sp,
            ),
          ],
        ),
      ],
    );
  }
}
