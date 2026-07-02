import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/features/leaderboard/models/leaderboard_participant.dart';
import 'package:test_steps/features/leaderboard/widgets/leaderboard_avatar.dart';
import 'package:test_steps/widgets/shared/app_borders.dart';

class LeaderboardPodiumCard extends StatelessWidget {
  const LeaderboardPodiumCard({
    super.key,
    required this.participants,
    required this.metric,
  });

  final List<LeaderboardParticipant> participants;
  final LeaderboardMetric metric;

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
            child: LeaderboardPodiumMember(
              participant: participants[1],
              metric: metric,
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: 30.h),
              child: LeaderboardPodiumMember(
                participant: participants[0],
                metric: metric,
              ),
            ),
          ),
          Expanded(
            child: LeaderboardPodiumMember(
              participant: participants[2],
              metric: metric,
            ),
          ),
        ],
      ),
    );
  }
}

class LeaderboardPodiumMember extends StatelessWidget {
  const LeaderboardPodiumMember({
    super.key,
    required this.participant,
    required this.metric,
  });

  final LeaderboardParticipant participant;
  final LeaderboardMetric metric;

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
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
          decoration: BoxDecoration(
            color: AppColors.lightBlueColor,
            borderRadius: BorderRadius.circular(18.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _metricIcon(metric),
                size: 16.sp,
                color: AppColors.textPrimary,
              ),
              6.horizontalSpace,
              Text(
                '${participant.score}',
                style: AppTextStyles.montserrat(
                  size: 14.sp,
                  color: AppColors.textPrimary,
                  weight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _metricIcon(LeaderboardMetric metric) {
    switch (metric) {
      case LeaderboardMetric.territoryTiles:
        return Icons.grid_view_rounded;
      case LeaderboardMetric.totalSteps:
        return Icons.directions_walk_rounded;
      case LeaderboardMetric.raidsWon:
        return Icons.local_fire_department_rounded;
      case LeaderboardMetric.territoryEnergy:
        return Icons.bolt_rounded;
    }
  }
}
