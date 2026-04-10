import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/constants/app_emojis.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/features/social/models/rank_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Sample data
// ─────────────────────────────────────────────────────────────────────────────

final _ranks = [
  SpecialRank(
    cardColor: const Color(0xFFFFF0EE),
    iconEmoji: AppEmojis.swords,
    title: 'Top Raider',
    titleColor: AppColors.error,
    playerEmoji: AppEmojis.wolf,
    playerName: 'IronStrider',
    statValue: '35 raids',
    statColor: AppColors.error,
    statDescription: 'Most attacks this season',
  ),
  SpecialRank(
    cardColor: const Color(0xFFEDFDF4),
    iconEmoji: AppEmojis.shield,
    title: 'Iron Shield',
    titleColor: AppColors.success,
    playerEmoji: AppEmojis.shield,
    playerName: 'TitanWalk',
    statValue: '18 defenses',
    statColor: AppColors.success,
    statDescription: 'Most raids repelled',
  ),
  SpecialRank(
    cardColor: const Color(0xFFFFF6E8),
    iconEmoji: AppEmojis.shoes,
    title: 'Pavement King',
    titleColor: AppColors.warning,
    playerEmoji: AppEmojis.fire,
    playerName: 'SwiftBlaze',
    statValue: '91,200 steps',
    statColor: AppColors.warning,
    statDescription: 'Most steps walked',
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Main Widget
// ─────────────────────────────────────────────────────────────────────────────

class SpecialRankingsSection extends StatelessWidget {
  const SpecialRankingsSection({super.key, this.ranks});

  final List<SpecialRank>? ranks;

  @override
  Widget build(BuildContext context) {
    final list = ranks ?? _ranks;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ───────────────────────────────────────────────────────────
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Row(
            children: [
              Icon(
                Icons.star_border_rounded,
                color: AppColors.textNavy,
                size: 20.r,
              ),
              SizedBox(width: 6.w),
              Text('Special Rankings', style: AppTextStyles.heading3),
            ],
          ),
        ),

        SizedBox(height: 14.h),

        // ── Cards row ────────────────────────────────────────────────────────
        Row(
          children: list
              .map(
                (r) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: r == list.last ? 0 : 10.w),
                    child: _RankCard(rank: r),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widget
// ─────────────────────────────────────────────────────────────────────────────

class _RankCard extends StatelessWidget {
  const _RankCard({required this.rank});
  final SpecialRank rank;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: rank.cardColor,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: rank.titleColor.withValues(alpha: 0.08),
            blurRadius: 12.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category icon
          Text(rank.iconEmoji, style: AppTextStyles.bodySmall),

          8.verticalSpace,

          // Title
          Text(
            rank.title,
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 13.sp,
              color: rank.titleColor,
              fontWeight: FontWeight.w700,
            ),
          ),

          6.verticalSpace,

          // Player row
          Row(
            children: [
              Text(rank.playerEmoji, style: AppTextStyles.bodySmall),
              4.horizontalSpace,
              Flexible(
                child: Text(
                  rank.playerName,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 12.sp,
                    color: AppColors.textNavy,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          8.verticalSpace,

          // Stat value
          Text(
            rank.statValue,
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 13.sp,
              color: rank.statColor,
              fontWeight: FontWeight.w800,
            ),
          ),

          2.verticalSpace,

          // Stat description
          Text(
            rank.statDescription,
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 10.5.sp,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
