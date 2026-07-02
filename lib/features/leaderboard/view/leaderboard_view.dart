import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/features/leaderboard/models/leaderboard_participant.dart';
import 'package:test_steps/features/leaderboard/widgets/leaderboard_participant_tile.dart';
import 'package:test_steps/features/leaderboard/widgets/leaderboard_podium_card.dart';
import 'package:test_steps/features/leaderboard/widgets/leaderboard_scope_switcher.dart';
import 'package:test_steps/features/profile/view/profile_bottom_sheet.dart';
import 'package:test_steps/providers/leaderboard_provider.dart';
import 'package:test_steps/screens/notifications_screen.dart';
import 'package:test_steps/services/dashboard_service.dart';
import 'package:test_steps/widgets/shared/app_borders.dart';
import 'package:test_steps/widgets/shared/dashboard_screen_header.dart';

class LeaderboardView extends ConsumerWidget {
  const LeaderboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(dashboardProvider);
    final leaderboard = ref.watch(leaderboardProvider);
    final notifier = ref.read(leaderboardProvider.notifier);
    final selectedIndex = LeaderboardMetric.values.indexOf(
      leaderboard.selectedMetric,
    );
    final participants = leaderboard.participants;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: Stack(
        children: [
          IgnorePointer(
            child: Image.asset(
              'assets/images/back.png',
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          ),
          SafeArea(
            bottom: false,
            child: RefreshIndicator(
              onRefresh: notifier.refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 28.h),
                children: [
                  DashboardScreenHeader(
                    title: 'Hi, ${dashboard.username}',
                    energy: dashboard.attackEnergy,
                    onNotificationsTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      );
                    },
                    onProfileTap: () {
                      showProfileBottomSheet(context);
                    },
                  ),
                  18.verticalSpace,
                  LeaderboardScopeSwitcher(
                    selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
                    onChanged: (index) =>
                        notifier.selectMetric(LeaderboardMetric.values[index]),
                  ),
                  12.verticalSpace,
                  if (leaderboard.data != null)
                    _SeasonSummaryCard(data: leaderboard.data!),
                  if (leaderboard.data != null) 12.verticalSpace,
                  if (leaderboard.isLoading && leaderboard.data == null)
                    const _LeaderboardStateCard(
                      icon: Icons.hourglass_top_rounded,
                      title: 'Loading leaderboard',
                      message: 'Fetching current season rankings.',
                    )
                  else if (leaderboard.error != null && participants.isEmpty)
                    _LeaderboardStateCard(
                      icon: Icons.error_outline_rounded,
                      title: 'Leaderboard unavailable',
                      message: leaderboard.error!,
                      actionLabel: 'Retry',
                      onAction: notifier.refresh,
                    )
                  else if (participants.isEmpty)
                    const _LeaderboardStateCard(
                      icon: Icons.leaderboard_rounded,
                      title: 'No rankings yet',
                      message: 'Walk, claim territory, or win raids to appear.',
                    )
                  else ...[
                    if (participants.length >= 3) ...[
                      LeaderboardPodiumCard(
                        participants: participants,
                        metric: leaderboard.selectedMetric,
                      ),
                      12.verticalSpace,
                      ...participants
                          .skip(3)
                          .map(
                            (participant) => Padding(
                              padding: EdgeInsets.only(bottom: 12.h),
                              child: LeaderboardParticipantTile(
                                participant: participant,
                                metric: leaderboard.selectedMetric,
                              ),
                            ),
                          ),
                    ] else
                      ...participants.map(
                        (participant) => Padding(
                          padding: EdgeInsets.only(bottom: 12.h),
                          child: LeaderboardParticipantTile(
                            participant: participant,
                            metric: leaderboard.selectedMetric,
                          ),
                        ),
                      ),
                    if (leaderboard.data != null) ...[
                      4.verticalSpace,
                      _SpecialRankingsSection(
                        rankings: leaderboard.data!.specialRankings,
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SeasonSummaryCard extends StatelessWidget {
  const _SeasonSummaryCard({required this.data});

  final LeaderboardData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22.r),
        border: AppBorders.raised(),
      ),
      child: Row(
        children: [
          Container(
            width: 42.w,
            height: 42.w,
            decoration: BoxDecoration(
              color: AppColors.currentUserChip,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Icon(
              Icons.emoji_events_rounded,
              color: AppColors.green,
              size: 22.sp,
            ),
          ),
          12.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.season.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.montserrat(
                    size: 14.sp,
                    color: AppColors.textPrimary,
                    weight: FontWeight.w700,
                  ),
                ),
                4.verticalSpace,
                Text(
                  _seasonRange(data.season),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.montserrat(
                    size: 12.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${data.participants.length} players',
            style: AppTextStyles.montserrat(
              size: 12.sp,
              color: AppColors.textSecondary,
              weight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _seasonRange(LeaderboardSeason season) {
    final start = season.startedAt;
    final end = season.endsAt;
    if (start == null && end == null) return 'Seasonal rankings reset here';
    if (end == null) return 'Started ${_shortDate(start!)}';
    if (start == null) return 'Ends ${_shortDate(end)}';
    return '${_shortDate(start)} - ${_shortDate(end)}';
  }

  String _shortDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}

class _SpecialRankingsSection extends StatelessWidget {
  const _SpecialRankingsSection({required this.rankings});

  final LeaderboardSpecialRankings rankings;

  @override
  Widget build(BuildContext context) {
    final items = [
      _SpecialRankingData(
        title: 'Most aggressive',
        participant: rankings.mostAggressive,
        value: rankings.mostAggressive?.attacksStarted ?? 0,
        suffix: 'attacks',
        icon: Icons.local_fire_department_rounded,
        color: AppColors.orange,
      ),
      _SpecialRankingData(
        title: 'Best defender',
        participant: rankings.bestDefender,
        value: rankings.bestDefender?.defensesWon ?? 0,
        suffix: 'defenses',
        icon: Icons.shield_rounded,
        color: AppColors.info,
      ),
      _SpecialRankingData(
        title: 'Most consistent',
        participant: rankings.mostConsistent,
        value: rankings.mostConsistent?.activeWalkDays ?? 0,
        suffix: 'days',
        icon: Icons.directions_walk_rounded,
        color: AppColors.green,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Special Rankings',
          style: AppTextStyles.montserrat(
            size: 16.sp,
            color: AppColors.textPrimary,
            weight: FontWeight.w700,
          ),
        ),
        10.verticalSpace,
        ...items.map(
          (item) => Padding(
            padding: EdgeInsets.only(bottom: 10.h),
            child: _SpecialRankingTile(item: item),
          ),
        ),
      ],
    );
  }
}

class _SpecialRankingTile extends StatelessWidget {
  const _SpecialRankingTile({required this.item});

  final _SpecialRankingData item;

  @override
  Widget build(BuildContext context) {
    final participant = item.participant;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18.r),
        border: AppBorders.raised(),
      ),
      child: Row(
        children: [
          Container(
            width: 42.w,
            height: 42.w,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(15.r),
            ),
            child: Icon(item.icon, color: item.color, size: 22.sp),
          ),
          12.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: AppTextStyles.montserrat(
                    size: 13.sp,
                    color: AppColors.textSecondary,
                    weight: FontWeight.w600,
                  ),
                ),
                4.verticalSpace,
                Text(
                  participant?.name ?? 'No leader yet',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.montserrat(
                    size: 14.sp,
                    color: AppColors.textPrimary,
                    weight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${item.value} ${item.suffix}',
            style: AppTextStyles.montserrat(
              size: 12.sp,
              color: AppColors.textSecondary,
              weight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardStateCard extends StatelessWidget {
  const _LeaderboardStateCard({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 26.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22.r),
        border: AppBorders.raised(),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 30.sp),
          12.verticalSpace,
          Text(
            title,
            style: AppTextStyles.montserrat(
              size: 16.sp,
              color: AppColors.textPrimary,
              weight: FontWeight.w700,
            ),
          ),
          6.verticalSpace,
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.montserrat(
              size: 13.sp,
              color: AppColors.textSecondary,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            14.verticalSpace,
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class _SpecialRankingData {
  const _SpecialRankingData({
    required this.title,
    required this.participant,
    required this.value,
    required this.suffix,
    required this.icon,
    required this.color,
  });

  final String title;
  final LeaderboardParticipant? participant;
  final int value;
  final String suffix;
  final IconData icon;
  final Color color;
}
