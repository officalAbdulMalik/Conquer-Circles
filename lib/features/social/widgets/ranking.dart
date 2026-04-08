import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/constants/app_emojis.dart';
import 'package:test_steps/core/theme/app_colors.dart';
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
  const SpecialRankingsSection({
    super.key,
    this.ranks,
  });

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
              Text(
                'Special Rankings',
                style: TextStyle(
                  color: AppColors.textNavy,
                  fontWeight: FontWeight.w800,
                  fontSize: 18.sp,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 14.h),

        // ── Cards row ────────────────────────────────────────────────────────
        Row(
          children: list
              .map((r) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: r == list.last ? 0 : 10.w,
                      ),
                      child: _RankCard(rank: r),
                    ),
                  ))
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
            color: rank.titleColor.withOpacity(0.08),
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
          Text(rank.iconEmoji, style: TextStyle(fontSize: 22.sp)),

          SizedBox(height: 8.h),

          // Title
          Text(
            rank.title,
            style: TextStyle(
              color: rank.titleColor,
              fontWeight: FontWeight.w700,
              fontSize: 13.sp,
            ),
          ),

          SizedBox(height: 6.h),

          // Player row
          Row(
            children: [
              Text(rank.playerEmoji, style: TextStyle(fontSize: 13.sp)),
              SizedBox(width: 4.w),
              Flexible(
                child: Text(
                  rank.playerName,
                  style: TextStyle(
                    color: AppColors.textNavy,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          SizedBox(height: 8.h),

          // Stat value
          Text(
            rank.statValue,
            style: TextStyle(
              color: rank.statColor,
              fontWeight: FontWeight.w800,
              fontSize: 13.sp,
            ),
          ),

          SizedBox(height: 2.h),

          // Stat description
          Text(
            rank.statDescription,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10.5.sp,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
