import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_spacing.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/features/seasons/widgets/season_recap_achievement_tile.dart';
import 'package:test_steps/features/seasons/widgets/season_recap_scope_switcher.dart';
import 'package:test_steps/features/seasons/widgets/season_recap_section_card.dart';
import 'package:test_steps/features/seasons/widgets/season_recap_stat_tile.dart';
import 'package:test_steps/features/seasons/widgets/season_recap_summary_card.dart';
import 'package:test_steps/services/game_service.dart';

final seasonRecapProvider = FutureProvider.family<Map<String, dynamic>?, int>((
  ref,
  seasonId,
) {
  return GameService().getMySeasonRecap(seasonId);
});

class SeasonRecapView extends ConsumerStatefulWidget {
  const SeasonRecapView({
    super.key,
    required this.seasonId,
    required this.seasonName,
  });

  final int seasonId;
  final String seasonName;

  @override
  ConsumerState<SeasonRecapView> createState() => _SeasonRecapViewState();
}

class _SeasonRecapViewState extends ConsumerState<SeasonRecapView> {
  bool isAllTime = true;

  @override
  Widget build(BuildContext context) {
    final recapData = ref.watch(seasonRecapProvider(widget.seasonId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: recapData.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.brandPurple),
          ),
          error: (e, s) => Center(
            child: Padding(
              padding: AppSpacing.pagePadding,
              child: Text(
                'Could not load recap right now.\n$e',
                textAlign: TextAlign.center,
                style: AppTextStyles.inter(
                  size: 14,
                  color: AppColors.textSecondary,
                  weight: FontWeight.w500,
                ),
              ),
            ),
          ),
          data: (recap) {
            final uiData = SeasonRecapDisplayData.fromMap(
              recap: recap,
              seasonName: widget.seasonName,
            );
            final statSet = isAllTime ? uiData.allTimeStats : uiData.seasonStats;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 24.h),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.brandPurple, AppColors.brandCyan],
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(24.r),
                        bottomRight: Radius.circular(24.r),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            DecoratedBox(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.surface.withValues(alpha: 0.2),
                              ),
                              child: IconButton(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color: AppColors.surface,
                                  size: 16.sp,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 9.w,
                                vertical: 5.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surface.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(999.r),
                              ),
                              child: Text(
                                uiData.endsInLabel,
                                style: AppTextStyles.inter(
                                  size: 10,
                                  color: AppColors.surface,
                                  weight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        2.verticalSpace,
                        Text('🏅', style: TextStyle(fontSize: 20.sp)),
                        4.verticalSpace,
                        Text(
                          'Season ${widget.seasonName} Recap',
                          style: AppTextStyles.poppins(
                            size: 23,
                            color: AppColors.surface,
                            weight: FontWeight.w700,
                          ),
                        ),
                        4.verticalSpace,
                        Text(
                          'Your journey, your impact, your legacy!',
                          style: AppTextStyles.inter(
                            size: 11,
                            color: AppColors.surface.withValues(alpha: 0.85),
                            weight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Transform.translate(
                    offset: Offset(0, -12.h),
                    child: Padding(
                      padding: AppSpacing.pagePadding,
                      child: Column(
                        children: [
                          SeasonRecapSummaryCard(
                            territories: uiData.territories,
                            rankLabel: uiData.rankLabel,
                            scoreLabel: uiData.scoreLabel,
                            rewardsUnlocked: uiData.rewardsUnlocked,
                          ),
                          10.verticalSpace,
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(color: AppColors.divider),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32.w,
                                  height: 32.w,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primaryLighter,
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Icon(
                                    Icons.person,
                                    size: 17.sp,
                                    color: AppColors.brandPurple,
                                  ),
                                ),
                                8.horizontalSpace,
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        uiData.playerName,
                                        style: AppTextStyles.poppins(
                                          size: 12,
                                          color: AppColors.textNavy,
                                          weight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        uiData.playerTagline,
                                        style: AppTextStyles.inter(
                                          size: 9,
                                          color: AppColors.textSecondary,
                                          weight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8.w,
                                    vertical: 4.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.bgSoftPurple,
                                    borderRadius: BorderRadius.circular(999.r),
                                  ),
                                  child: Text(
                                    uiData.rewardLabel,
                                    style: AppTextStyles.inter(
                                      size: 9,
                                      color: AppColors.brandPurple,
                                      weight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          10.verticalSpace,
                          SeasonRecapSectionCard(
                            title: 'Territory Report',
                            child: Column(
                              children: [
                                Container(
                                  height: 122.h,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12.r),
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        AppColors.brandPurple.withValues(alpha: 0.9),
                                        AppColors.brandCyan.withValues(alpha: 0.6),
                                        AppColors.error.withValues(alpha: 0.45),
                                      ],
                                    ),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.map_outlined,
                                      size: 42.sp,
                                      color: AppColors.surface.withValues(alpha: 0.9),
                                    ),
                                  ),
                                ),
                                8.verticalSpace,
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 8.h,
                                          horizontal: 8.w,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.bgLight,
                                          borderRadius: BorderRadius.circular(10.r),
                                        ),
                                        child: Column(
                                          children: [
                                            Icon(
                                              Icons.flag_outlined,
                                              size: 12.sp,
                                              color: AppColors.brandPurple,
                                            ),
                                            3.verticalSpace,
                                            Text(
                                              '${uiData.territories}',
                                              style: AppTextStyles.poppins(
                                                size: 12,
                                                color: AppColors.textNavy,
                                                weight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    6.horizontalSpace,
                                    Expanded(
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 8.h,
                                          horizontal: 8.w,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.bgLight,
                                          borderRadius: BorderRadius.circular(10.r),
                                        ),
                                        child: Column(
                                          children: [
                                            Icon(
                                              Icons.shield_outlined,
                                              size: 12.sp,
                                              color: AppColors.warning,
                                            ),
                                            3.verticalSpace,
                                            Text(
                                              '${uiData.defendedTiles}',
                                              style: AppTextStyles.poppins(
                                                size: 12,
                                                color: AppColors.textNavy,
                                                weight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    6.horizontalSpace,
                                    Expanded(
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 8.h,
                                          horizontal: 8.w,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.bgLight,
                                          borderRadius: BorderRadius.circular(10.r),
                                        ),
                                        child: Column(
                                          children: [
                                            Icon(
                                              Icons.whatshot_outlined,
                                              size: 12.sp,
                                              color: AppColors.error,
                                            ),
                                            3.verticalSpace,
                                            Text(
                                              '${uiData.hotZones}',
                                              style: AppTextStyles.poppins(
                                                size: 12,
                                                color: AppColors.textNavy,
                                                weight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          10.verticalSpace,
                          SeasonRecapSectionCard(
                            title: 'Season Stats',
                            trailing: SeasonRecapScopeSwitcher(
                              initialAllTime: isAllTime,
                              onChanged: (value) => setState(() => isAllTime = value),
                            ),
                            child: GridView.builder(
                              itemCount: statSet.length,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 8.h,
                                crossAxisSpacing: 8.w,
                                childAspectRatio: 2.05,
                              ),
                              itemBuilder: (context, index) {
                                final stat = statSet[index];
                                return SeasonRecapStatTile(
                                  icon: stat.icon,
                                  title: stat.title,
                                  value: stat.value,
                                  backgroundColor: stat.backgroundColor,
                                  valueColor: stat.valueColor,
                                );
                              },
                            ),
                          ),
                          10.verticalSpace,
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(11.w),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(color: AppColors.divider),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 28.w,
                                  height: 28.w,
                                  decoration: BoxDecoration(
                                    color: AppColors.warning.withValues(alpha: 0.14),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.local_fire_department_outlined,
                                    size: 15.sp,
                                    color: AppColors.warning,
                                  ),
                                ),
                                8.horizontalSpace,
                                Expanded(
                                  child: Text(
                                    '${uiData.streakDays}-Day Best Streak',
                                    style: AppTextStyles.poppins(
                                      size: 11,
                                      color: AppColors.textNavy,
                                      weight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Text(
                                  '🔥',
                                  style: TextStyle(fontSize: 14.sp),
                                ),
                              ],
                            ),
                          ),
                          10.verticalSpace,
                          SeasonRecapSectionCard(
                            title: 'Achievements Unlocked',
                            trailing: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(999.r),
                              ),
                              child: Text(
                                '${uiData.achievements.length} Earned',
                                style: AppTextStyles.inter(
                                  size: 9,
                                  color: AppColors.brandPurple,
                                  weight: FontWeight.w700,
                                ),
                              ),
                            ),
                            child: Column(
                              children: uiData.achievements
                                  .map(
                                    (achievement) => Padding(
                                      padding: EdgeInsets.only(bottom: 8.h),
                                      child: SeasonRecapAchievementTile(
                                        icon: achievement.icon,
                                        title: achievement.title,
                                        subtitle: achievement.subtitle,
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                          14.verticalSpace,
                          SizedBox(
                            width: double.infinity,
                            height: 41.h,
                            child: ElevatedButton.icon(
                              onPressed: () {},
                              icon: Icon(
                                Icons.ios_share_outlined,
                                size: 14.sp,
                                color: AppColors.surface,
                              ),
                              label: Text(
                                'Share All Cards',
                                style: AppTextStyles.poppins(
                                  size: 12,
                                  color: AppColors.surface,
                                  weight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor: AppColors.brandPurple,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                              ),
                            ),
                          ),
                          8.verticalSpace,
                          SizedBox(
                            width: double.infinity,
                            height: 38.h,
                            child: OutlinedButton.icon(
                              onPressed: () {},
                              icon: Icon(
                                Icons.image_outlined,
                                size: 14.sp,
                                color: AppColors.textSecondary,
                              ),
                              label: Text(
                                'Save to Gallery',
                                style: AppTextStyles.inter(
                                  size: 11,
                                  color: AppColors.textSecondary,
                                  weight: FontWeight.w600,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.divider),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                              ),
                            ),
                          ),
                          20.verticalSpace,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class SeasonRecapDisplayData {
  const SeasonRecapDisplayData({
    required this.playerName,
    required this.playerTagline,
    required this.endsInLabel,
    required this.rankLabel,
    required this.scoreLabel,
    required this.rewardLabel,
    required this.territories,
    required this.defendedTiles,
    required this.hotZones,
    required this.rewardsUnlocked,
    required this.streakDays,
    required this.allTimeStats,
    required this.seasonStats,
    required this.achievements,
  });

  final String playerName;
  final String playerTagline;
  final String endsInLabel;
  final String rankLabel;
  final String scoreLabel;
  final String rewardLabel;
  final int territories;
  final int defendedTiles;
  final int hotZones;
  final int rewardsUnlocked;
  final int streakDays;
  final List<SeasonStatItem> allTimeStats;
  final List<SeasonStatItem> seasonStats;
  final List<SeasonAchievementItem> achievements;

  factory SeasonRecapDisplayData.fromMap({
    required Map<String, dynamic>? recap,
    required String seasonName,
  }) {
    final int territories = parseRecapInt(recap?['tiles_captured'], 72);
    final int rewards = parseRecapInt(recap?['rewards_unlocked'], 8);
    final int totalSteps = parseRecapInt(recap?['total_steps'], 842000);
    final double distanceKm = parseRecapDouble(recap?['distance_km'], 387);
    final int calories = parseRecapInt(recap?['calories_burned'], 48300);
    final int avgHeartRate = parseRecapInt(recap?['avg_heart_rate'], 132);
    final int activeHours = parseRecapInt(recap?['active_hours'], 68);
    final int streak = parseRecapInt(recap?['best_streak_days'], 12);
    final int defended = parseRecapInt(recap?['tiles_defended'], 14);
    final int hotZones = parseRecapInt(recap?['hot_zones'], 3);
    final int teamRank = parseRecapInt(recap?['team_rank'], 2);

    return SeasonRecapDisplayData(
      playerName: 'FitWarrior_92',
      playerTagline: '#$teamRank in your league',
      endsInLabel: '4 days',
      rankLabel: '#$teamRank',
      scoreLabel: '${(totalSteps / 1000).toStringAsFixed(1)}k',
      rewardLabel: '#$teamRank / +4',
      territories: territories,
      defendedTiles: defended,
      hotZones: hotZones,
      rewardsUnlocked: rewards,
      streakDays: streak,
      allTimeStats: [
        SeasonStatItem(
          title: 'Total Steps',
          value: '${(totalSteps / 1000).toStringAsFixed(0)}K',
          icon: Icons.directions_walk_outlined,
          backgroundColor: AppColors.primaryLighter,
          valueColor: AppColors.brandPurple,
        ),
        SeasonStatItem(
          title: 'Calories',
          value: '${(calories / 1000).toStringAsFixed(1)}K',
          icon: Icons.local_fire_department_outlined,
          backgroundColor: AppColors.warning.withValues(alpha: 0.14),
          valueColor: AppColors.warning,
        ),
        SeasonStatItem(
          title: 'Distance',
          value: '${distanceKm.toStringAsFixed(0)} km',
          icon: Icons.route_outlined,
          backgroundColor: AppColors.info.withValues(alpha: 0.14),
          valueColor: AppColors.info,
        ),
        SeasonStatItem(
          title: 'Active Days',
          value: '$activeHours',
          icon: Icons.calendar_today_outlined,
          backgroundColor: AppColors.success.withValues(alpha: 0.14),
          valueColor: AppColors.success,
        ),
        SeasonStatItem(
          title: 'Avg Heart',
          value: '$avgHeartRate bpm',
          icon: Icons.favorite_border_rounded,
          backgroundColor: AppColors.error.withValues(alpha: 0.14),
          valueColor: AppColors.error,
        ),
        SeasonStatItem(
          title: 'Best Streak',
          value: '$streak days',
          icon: Icons.bolt_outlined,
          backgroundColor: AppColors.brandCyan.withValues(alpha: 0.2),
          valueColor: AppColors.brandPurple,
        ),
      ],
      seasonStats: [
        SeasonStatItem(
          title: 'Season Steps',
          value: '${(totalSteps / 1300).toStringAsFixed(0)}K',
          icon: Icons.directions_walk_outlined,
          backgroundColor: AppColors.primaryLighter,
          valueColor: AppColors.brandPurple,
        ),
        SeasonStatItem(
          title: 'Season Calories',
          value: '${(calories / 1600).toStringAsFixed(1)}K',
          icon: Icons.local_fire_department_outlined,
          backgroundColor: AppColors.warning.withValues(alpha: 0.14),
          valueColor: AppColors.warning,
        ),
        SeasonStatItem(
          title: 'Season Distance',
          value: '${(distanceKm * 0.72).toStringAsFixed(0)} km',
          icon: Icons.route_outlined,
          backgroundColor: AppColors.info.withValues(alpha: 0.14),
          valueColor: AppColors.info,
        ),
        SeasonStatItem(
          title: 'Active Days',
          value: (activeHours * 0.62).toStringAsFixed(0),
          icon: Icons.calendar_today_outlined,
          backgroundColor: AppColors.success.withValues(alpha: 0.14),
          valueColor: AppColors.success,
        ),
        SeasonStatItem(
          title: 'Avg Heart',
          value: '${(avgHeartRate - 4).toStringAsFixed(0)} bpm',
          icon: Icons.favorite_border_rounded,
          backgroundColor: AppColors.error.withValues(alpha: 0.14),
          valueColor: AppColors.error,
        ),
        SeasonStatItem(
          title: 'Season Streak',
          value: '${(streak * 0.8).toStringAsFixed(0)} days',
          icon: Icons.bolt_outlined,
          backgroundColor: AppColors.brandCyan.withValues(alpha: 0.2),
          valueColor: AppColors.brandPurple,
        ),
      ],
      achievements: [
        const SeasonAchievementItem(
          title: 'Territory King',
          subtitle: 'Captured 50+ tiles',
          icon: Icons.emoji_events_outlined,
        ),
        const SeasonAchievementItem(
          title: 'Marathon Runner',
          subtitle: 'Crossed 300 km in one season',
          icon: Icons.directions_run_outlined,
        ),
        const SeasonAchievementItem(
          title: 'Workout Beast',
          subtitle: 'Top 5% active days',
          icon: Icons.fitness_center_outlined,
        ),
        const SeasonAchievementItem(
          title: 'Team Player',
          subtitle: 'Helped secure 14 zones',
          icon: Icons.groups_2_outlined,
        ),
      ],
    );
  }
}

class SeasonStatItem {
  const SeasonStatItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.backgroundColor,
    required this.valueColor,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color backgroundColor;
  final Color valueColor;
}

class SeasonAchievementItem {
  const SeasonAchievementItem({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;
}

int parseRecapInt(dynamic value, int fallback) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value.toString()) ?? fallback;
}

double parseRecapDouble(dynamic value, double fallback) {
  if (value == null) return fallback;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? fallback;
}
