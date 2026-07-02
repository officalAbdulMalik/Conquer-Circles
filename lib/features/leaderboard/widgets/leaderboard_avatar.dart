import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/features/leaderboard/models/leaderboard_participant.dart';

class LeaderboardAvatar extends StatelessWidget {
  const LeaderboardAvatar({
    super.key,
    required this.participant,
    required this.size,
  });

  final LeaderboardParticipant participant;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size.w,
          height: size.w,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.lightBlueColor,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: AppColors.borderColor),
          ),
          child: participant.avatarUrl?.isNotEmpty == true
              ? Image.network(
                  participant.avatarUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      _AvatarFallback(participant: participant, size: size),
                )
              : participant.avatarAsset == null
              ? _AvatarFallback(participant: participant, size: size)
              : Image.asset(participant.avatarAsset!, fit: BoxFit.cover),
        ),
        if (participant.medal != null)
          Positioned(
            right: -7.w,
            bottom: -6.h,
            child: Container(
              width: 24.w,
              height: 24.w,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderColor),
              ),
              child: Text(
                participant.medal!,
                style: AppTextStyles.montserrat(
                  size: 13.sp,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.participant, required this.size});

  final LeaderboardParticipant participant;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initials = participant.name.trim().isEmpty
        ? '?'
        : participant.name
              .trim()
              .split(RegExp(r'\s+'))
              .take(2)
              .map((part) => part[0])
              .join()
              .toUpperCase();

    return Center(
      child: Text(
        participant.avatarEmoji ?? initials,
        style: AppTextStyles.montserrat(
          size: (size * 0.5).sp,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
