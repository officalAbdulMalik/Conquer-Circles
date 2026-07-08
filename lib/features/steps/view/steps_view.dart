import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/features/steps/view/badges_tab_section.dart';
import 'package:test_steps/features/steps/view/objective_tab_section.dart';
import 'package:test_steps/features/steps/view/player_energy_screen.dart';
import 'package:test_steps/features/steps/view/wearable_sync_screen.dart';
import 'package:test_steps/features/map/view/map_view.dart';
import 'package:test_steps/features/profile/view/profile_bottom_sheet.dart';
import 'package:test_steps/features/steps/view/overview_stats_section.dart';
import 'package:test_steps/features/steps/widgets/badge_detail_dialog.dart';
import 'package:test_steps/features/steps/widgets/badge_shimmer_grid.dart';
import 'package:test_steps/features/steps/widgets/badge_unlock_dialog.dart';
import 'package:test_steps/features/steps/widgets/steps_dashboard_tile.dart';
import 'package:test_steps/features/steps/widgets/steps_progress_painter.dart';
import 'package:test_steps/features/steps/view/territory_tab_section.dart';
import 'package:test_steps/models/dashboard_model.dart';
import 'package:test_steps/providers/ai_provider.dart';
import 'package:test_steps/providers/badge_provider.dart';
import 'package:test_steps/providers/circles_provider.dart';
import 'package:test_steps/providers/stats_range_provider.dart';
import 'package:test_steps/providers/wearable_provider.dart';
import 'package:test_steps/screens/notifications_screen.dart';
import 'package:test_steps/services/dashboard_service.dart';
import 'package:test_steps/widgets/shared/app_borders.dart';
import 'package:test_steps/widgets/shared/custom_app_dialog.dart';
import 'package:test_steps/widgets/shared/dashboard_screen_header.dart';
import 'package:test_steps/widgets/shared/dashboard_tab_button.dart';
import 'package:test_steps/widgets/shared/app_background_image.dart';

class StepsView extends ConsumerStatefulWidget {
  const StepsView({super.key});

  @override
  ConsumerState<StepsView> createState() => _StepsViewState();
}

class _StepsViewState extends ConsumerState<StepsView> {
  /// Selected dashboard tab — pure view state, so a ValueNotifier (no
  /// setState). Stats range/period logic lives in [statsRangeProvider].
  final ValueNotifier<int> _selectedDashboardTab = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final notifier = ref.read(dashboardProvider.notifier);
      await notifier.loadDashboard();
      await ref.read(statsRangeProvider.notifier).loadStatsGraph();
    });
  }

  @override
  void dispose() {
    _selectedDashboardTab.dispose();
    super.dispose();
  }

  final tabs = [
    ('Overview', null),
    ('Territory', 5),
    ('Objective', 5),
    ('Badges', null),
  ];

  void _openEnergyScreen(int energy) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PlayerEnergyScreen(energy: energy)),
    );
  }

  void _openWearableSyncScreen(int currentSteps) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WearableSyncScreen(currentSteps: currentSteps),
      ),
    );
  }

  void _showBadgeDetailDialog(BadgeCardData badge) {
    showCustomAppDialog<void>(
      context: context,
      dialog: badge.unlocked
          ? BadgeUnlockDialog(
              title: badge.title,
              description: _unlockedBadgeDescription(badge),
              iconUrl: badge.icon,
            )
          : BadgeDetailDialog(
              title: badge.title,
              description: badge.title == 'Step Rookie'
                  ? 'Walk 5,000 steps in a single day.'
                  : badge.subtitle,
              iconUrl: badge.icon,
              // Only steps badges show the linear steps progress bar.
              showProgress: badge.isStepsBadge,
              onContinueChallenge: () {
                Navigator.of(context).pop();
              },
            ),
    );
  }

  String _unlockedBadgeDescription(BadgeCardData badge) {
    if (badge.title == 'Daily Grinder') {
      return 'You crushed 10,000 steps for 5 straight\ndays. Consistency beats intensity.';
    }

    if (badge.title == 'Step Rookie') {
      return 'You walked 5,000 steps in a single day.\nYour first milestone is complete.';
    }

    return badge.subtitle;
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(dashboardProvider);
    final wearableState = ref.watch(wearableProvider);
    final watchSynced = wearableState.isConnected;
    final numberFormat = NumberFormat.decimalPattern();
    final goal = dashboardState.stepGoal > 0 ? dashboardState.stepGoal : 10000;
    final progress = (dashboardState.steps / goal).clamp(0.0, 1.0);
    final totalArea = math.max(dashboardState.totalAreaKm2, 0).toDouble();
    final duration = _formatDuration(dashboardState.durationSeconds);
    final summaryItems = [
      ('${dashboardState.distanceKm.toStringAsFixed(2)}km', 'Total Distance'),
      (duration, 'Duration'),
      ('${totalArea.toStringAsFixed(1)} km²', 'Total Area'),
    ];

    return Scaffold(
      body: Stack(
        children: [
          AppBackgroundImage(),
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(24.w, 18.h, 24.w, 28.h),
              child: ValueListenableBuilder<int>(
                valueListenable: _selectedDashboardTab,
                builder: (context, selectedTab, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DashboardScreenHeader(
                    title: 'Hi, ${dashboardState.username}',
                    energy: dashboardState.attackEnergy,
                    onEnergyTap: () =>
                        _openEnergyScreen(dashboardState.attackEnergy),
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
                  if (dashboardState.error != null) ...[
                    12.verticalSpace,
                    _DashboardErrorBanner(
                      message: dashboardState.error!,
                      onRetry: () => ref
                          .read(dashboardProvider.notifier)
                          .loadDashboard(force: true),
                    ),
                  ],
                  18.verticalSpace,
                  if (selectedTab == 2)
                    ObjectiveEnergyHeader(
                      username: dashboardState.username,
                      energy: dashboardState.attackEnergy,
                      targetEnergy: dashboardState.attackEnergyCap,
                      level: dashboardState.level,
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: 18.w,
                        vertical: 22.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDDEBFF),
                        borderRadius: BorderRadius.circular(24.r),
                        border: AppBorders.raised(),
                      ),
                      child: Row(
                        children: summaryItems
                            .map(
                              (item) => Expanded(
                                child: Column(
                                  children: [
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        item.$1,
                                        style: AppTextStyles.montserrat(
                                          size: 20,
                                          color: AppColors.textPrimary,
                                          weight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    6.verticalSpace,
                                    Text(
                                      item.$2,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.montserrat(
                                        size: 14.sp,
                                        weight: FontWeight.w400,

                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  22.verticalSpace,
                  const StepsCircleJoinRequestsSection(),
                  24.verticalSpace,
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: tabs.map((tab) {
                        final index = tabs.indexOf(tab);
                        final selected = selectedTab == index;

                        return Padding(
                          padding: EdgeInsets.only(right: 8.w),
                          child: DashboardTabButton(
                            label: tab.$1,
                            count: tab.$2,
                            selected: selected,
                            onTap: () {
                              _selectedDashboardTab.value = index;
                              if (index == 1) {
                                ref
                                    .read(dashboardProvider.notifier)
                                    .refreshTerritoryHistory();
                              }
                              if (index == 2) {
                                final aiState = ref.read(aiProvider);
                                if (aiState.objectives.isEmpty &&
                                    !aiState.isLoadingObjectives) {
                                  ref
                                      .read(aiProvider.notifier)
                                      .fetchObjectives(
                                        ref.read(dashboardProvider),
                                      );
                                }
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  24.verticalSpace,
                  if (selectedTab == 0) ...[
                    Container(
                      width: double.infinity,

                      padding: EdgeInsets.symmetric(
                        horizontal: 22.w,
                        vertical: 20.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22.r),
                        border: AppBorders.raised(),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20.r),

                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Today Steps',
                                    style: AppTextStyles.montserrat(
                                      size: 15.sp,
                                      color: AppColors.textPrimary,
                                      weight: FontWeight.w400,
                                    ),
                                  ),
                                  8.verticalSpace,
                                  Text(
                                    numberFormat.format(dashboardState.steps),
                                    style: AppTextStyles.montserrat(
                                      size: 22.sp,
                                      color: AppColors.textPrimary,
                                      weight: FontWeight.w800,
                                      height: 1.1,
                                    ),
                                  ),
                                  6.verticalSpace,
                                  Text(
                                    '${numberFormat.format(goal)} Target',
                                    style: AppTextStyles.montserrat(
                                      size: 14.sp,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 166.w,
                              height: 92.h,
                              child: CustomPaint(
                                painter: StepsProgressPainter(
                                  progress: progress,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    20.verticalSpace,
                    GridView(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 18.w,
                        mainAxisSpacing: 18.h,
                        childAspectRatio: 0.78,
                      ),
                      children: [
                        StepsDashboardTile(
                          title: 'Today Kcal Burned',
                          value: numberFormat.format(dashboardState.calories),
                          icon: 'assets/icons/power.png',
                          iconBackgroundColor: const Color(0xFFD8E9FF),
                          isLoading: dashboardState.isLoading,
                          footer: '18+ since last week',
                          footerIcon: Icons.arrow_upward_rounded,
                          footerIconColor: AppColors.success,
                        ),
                        watchSynced
                            ? WearableSyncedTile(
                                stepsLabel: numberFormat.format(
                                  dashboardState.steps > 0
                                      ? dashboardState.steps
                                      : wearableState.syncedSteps,
                                ),
                                onTap: () => _openWearableSyncScreen(
                                  dashboardState.steps,
                                ),
                              )
                            : WearableConnectTile(
                                onTap: () => _openWearableSyncScreen(
                                  dashboardState.steps,
                                ),
                              ),
                        StepsDashboardTile(
                          title: 'Streak',
                          value: '${dashboardState.weeklyStreak}',
                          unit: 'days',
                          icon: 'assets/icons/streak.png',
                          iconBackgroundColor: const Color(0xFFDDEBFF),
                          isLoading: dashboardState.isLoading,
                          footer: 'Current streak',
                        ),
                        StepsDashboardTile(
                          title: 'Today Energy',
                          value: '${dashboardState.attackEnergy}',
                          icon: 'assets/icons/battery.png',
                          iconBackgroundColor: const Color(0xffDBEAFE),
                          isLoading: dashboardState.isLoading,
                          footer: 'Available energy',
                          onTap: () =>
                              _openEnergyScreen(dashboardState.attackEnergy),
                        ),
                      ],
                    ),
                    if (!watchSynced) ...[
                      14.verticalSpace,
                      WearableSyncRequiredBanner(
                        onConnectTap: () =>
                            _openWearableSyncScreen(dashboardState.steps),
                      ),
                    ],
                    22.verticalSpace,
                    Consumer(
                      builder: (context, ref, _) {
                        final statsRange = ref.watch(statsRangeProvider);
                        final rangeNotifier =
                            ref.read(statsRangeProvider.notifier);
                        return OverviewStatsSection(
                          distanceDays: dashboardState.distanceGraphDays,
                          isDistanceLoading: dashboardState.isGraphLoading,
                          distanceError: dashboardState.graphError,
                          territoryDays: dashboardState.territoryGraphDays,
                          isTerritoryLoading:
                              dashboardState.isTerritoryGraphLoading,
                          territoryError: dashboardState.territoryGraphError,
                          selectedRange: statsRange.range,
                          periodStart: statsRange.periodStart,
                          periodEnd: statsRange.periodEnd,
                          canNavigatePrevious: statsRange.range !=
                              DashboardStatsRange.allTime,
                          canNavigateNext: statsRange.canNavigateNext,
                          onRangeChanged: rangeNotifier.selectRange,
                          onPreviousPeriod: () =>
                              rangeNotifier.changePeriod(-1),
                          onNextPeriod: () => rangeNotifier.changePeriod(1),
                          onRetryDistance: rangeNotifier.loadStatsGraph,
                        );
                      },
                    ),
                  ] else if (selectedTab == 1)
                    TerritoryTabSection(
                      onViewMap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const MapView()),
                        );
                      },
                      onHistoryTap: () {},
                      onViewTerritory: () {},
                      history: dashboardState.territoryHistory,
                    )
                  else if (selectedTab == 2)
                    _buildObjectiveTab(ref)
                  else
                    ref
                        .watch(allBadgesProvider)
                        .when(
                          data: (allBadges) => BadgesTabSection(
                            badges: allBadges.isNotEmpty
                                ? allBadges
                                : dashboardState.badges,
                            onSearchTap: () {},
                            onFilterTap: () {},
                            onBadgeTap: _showBadgeDetailDialog,
                          ),
                          loading: () => const BadgesShimmerGrid(),
                          error: (_, __) => BadgesTabSection(
                            badges: dashboardState.badges,
                            onSearchTap: () {},
                            onFilterTap: () {},
                            onBadgeTap: _showBadgeDetailDialog,
                          ),
                        ),
                ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildObjectiveTab(WidgetRef ref) {
    final aiState = ref.watch(aiProvider);

    const icons = [
      'assets/icons/walk.png',
      'assets/icons/streak.png',
      'assets/icons/battery.png',
    ];
    const iconColors = [
      Color(0xFF5397FF),
      Color(0xFFFF6B6B),
      Color(0xFF8C70F8),
    ];
    const bgColors = [Color(0xFFD8E9FF), Color(0xFFFFE0E0), Color(0xFFEDE9FF)];

    final aiObjectives = aiState.objectives.asMap().entries.map((entry) {
      final i = entry.key % 3;
      final obj = entry.value;
      return ObjectiveTaskData(
        type: ObjectiveTaskType.aiGenerated,
        title: obj.title,
        progressLabel: obj.progressLabel,
        percent: obj.percent,
        icon: icons[i],
        iconColor: iconColors[i],
        iconBackgroundColor: bgColors[i],
      );
    }).toList();

    return ObjectiveTabSection(
      badgeProgressObjectives: const [],
      aiGeneratedObjectives: aiObjectives,
      isAiLoading: aiState.isLoadingObjectives,
    );
  }

  String _formatDuration(int seconds) {
    final safeSeconds = math.max(0, seconds);
    final hours = safeSeconds ~/ 3600;
    final minutes = (safeSeconds % 3600) ~/ 60;
    final remainingSeconds = safeSeconds % 60;
    return '$hours:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}

class _DashboardErrorBanner extends StatelessWidget {
  const _DashboardErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626)),
          10.horizontalSpace,
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.montserrat(
                size: 12.sp,
                color: const Color(0xFF991B1B),
                weight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class WearableConnectTile extends StatelessWidget {
  const WearableConnectTile({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22.r),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 18.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22.r),
          border: AppBorders.raised(),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                width: 34.w,
                height: 34.w,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderColor, width: 1.w),
                ),
                child: Icon(
                  Icons.watch_outlined,
                  size: 18.sp,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            46.verticalSpace,
            Text(
              'Connect Wearable',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.montserrat(
                size: 15.sp,
                color: AppColors.textPrimary,
                weight: FontWeight.w600,
              ),
            ),
            8.verticalSpace,
            Align(
              alignment: Alignment.center,
              child: GestureDetector(
                onTap: onTap,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 17.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.blueColor,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.blueColor.withValues(alpha: 0.24),
                        blurRadius: 10.r,
                        offset: Offset(0, 4.h),
                      ),
                    ],
                  ),
                  child: Text(
                    'Connect',
                    style: AppTextStyles.montserrat(
                      size: 13.sp,
                      color: Colors.white,
                      weight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Home-screen tile shown once the watch is connected: displays the steps
/// synced from the watch (via Apple Health / Health Connect) instead of the
/// "Connect" call-to-action.
class WearableSyncedTile extends StatelessWidget {
  const WearableSyncedTile({
    super.key,
    required this.stepsLabel,
    this.onTap,
  });

  final String stepsLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final sourceLabel = defaultTargetPlatform == TargetPlatform.iOS
        ? 'Apple Watch'
        : 'your watch';

    return InkWell(
      borderRadius: BorderRadius.circular(22.r),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 18.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22.r),
          border: AppBorders.raised(),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34.w,
                  height: 34.w,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8FBEF),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.watch_rounded,
                    size: 18.sp,
                    color: AppColors.success,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.check_circle_rounded,
                  size: 18.sp,
                  color: AppColors.success,
                ),
              ],
            ),
            18.verticalSpace,
            Text(
              stepsLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.montserrat(
                size: 24.sp,
                color: AppColors.textPrimary,
                weight: FontWeight.w800,
              ),
            ),
            2.verticalSpace,
            Text(
              'Watch Steps',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.montserrat(
                size: 13.sp,
                color: AppColors.textPrimary,
                weight: FontWeight.w600,
              ),
            ),
            6.verticalSpace,
            Text(
              'Synced from $sourceLabel',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.montserrat(
                size: 11.sp,
                color: AppColors.textSecondary,
                weight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WearableSyncRequiredBanner extends StatelessWidget {
  const WearableSyncRequiredBanner({super.key, required this.onConnectTap});

  final VoidCallback onConnectTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(12.w, 12.h, 14.w, 12.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEFF6FF), Color(0xFFCFE3FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: const Color(0xFFBBD7FF), width: 1.w),
      ),
      child: Row(
        children: [
          Container(
            width: 76.w,
            height: 76.w,
            decoration: BoxDecoration(
              color: const Color(0xFFE9DDFF),
              borderRadius: BorderRadius.circular(18.r),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Transform.rotate(
                  angle: -0.35,
                  child: Container(
                    width: 45.w,
                    height: 58.h,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: const Color(0xFFD9D0FF),
                        width: 1.w,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '14\n20',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.montserrat(
                          size: 14.sp,
                          color: AppColors.textPrimary,
                          weight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          18.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sync Required',
                  style: AppTextStyles.montserrat(
                    size: 15.sp,
                    color: AppColors.textPrimary,
                    weight: FontWeight.w800,
                  ),
                ),
                6.verticalSpace,
                Text(
                  'Connect wearable to track',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.montserrat(
                    size: 13.sp,
                    color: AppColors.textPrimary,
                    weight: FontWeight.w500,
                  ),
                ),
                10.verticalSpace,
                GestureDetector(
                  onTap: onConnectTap,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 18.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.blueColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Connect Device',
                      style: AppTextStyles.montserrat(
                        size: 13.sp,
                        color: Colors.white,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StepsCircleJoinRequest {
  const StepsCircleJoinRequest({
    required this.id,
    required this.name,
    required this.circleName,
    this.avatarUrl,
    this.avatarColor = AppColors.lightBlueColor,
  });

  final String id;
  final String name;
  final String circleName;
  final String? avatarUrl;
  final Color avatarColor;
}

class StepsCircleJoinRequestsSection extends ConsumerWidget {
  const StepsCircleJoinRequestsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final circlesState = ref.watch(circlesProvider);
    final requests = circlesState.incomingJoinRequests.map((request) {
      return StepsCircleJoinRequest(
        id: request.id,
        name: request.requesterName,
        circleName: request.circleName,
        avatarUrl: request.avatarUrl,
      );
    }).toList();

    if (requests.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Circle Invites',
                style: AppTextStyles.montserrat(
                  size: 18.sp,
                  color: AppColors.textPrimary,
                  weight: FontWeight.w800,
                ),
              ),
            ),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
              ),
              child: Text(
                'View All',
                style: AppTextStyles.montserrat(
                  size: 13.sp,
                  color: AppColors.blueColor,
                  weight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        12.verticalSpace,
        ...List.generate(requests.length, (index) {
          final request = requests[index];
          final isLoading = circlesState.respondingRequestIds.contains(
            request.id,
          );
          return Padding(
            padding: EdgeInsets.only(
              bottom: index == requests.length - 1 ? 0 : 12.h,
            ),
            child: StepsCircleJoinRequestTile(
              request: request,
              isLoading: isLoading,
              onAccept: () => ref
                  .read(circlesProvider.notifier)
                  .respondToJoinRequest(requestId: request.id, accept: true),
              onDelete: () => ref
                  .read(circlesProvider.notifier)
                  .respondToJoinRequest(requestId: request.id, accept: false),
            ),
          );
        }),
      ],
    );
  }
}

class StepsCircleJoinRequestTile extends StatelessWidget {
  const StepsCircleJoinRequestTile({
    super.key,
    required this.request,
    required this.onAccept,
    required this.onDelete,
    this.isLoading = false,
  });

  final StepsCircleJoinRequest request;
  final VoidCallback onAccept;
  final VoidCallback onDelete;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(18.w, 14.h, 18.w, 14.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: AppBorders.raised(),
      ),
      child: Row(
        children: [
          Container(
            width: 58.w,
            height: 58.w,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: request.avatarColor,
              borderRadius: BorderRadius.circular(18.r),
            ),
            clipBehavior: Clip.antiAlias,
            child: request.avatarUrl?.trim().isNotEmpty == true
                ? Image.network(
                    request.avatarUrl!,
                    width: 56.w,
                    height: 56.w,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.person_rounded,
                      color: AppColors.blueColor,
                    ),
                  )
                : const Icon(Icons.person_rounded, color: AppColors.blueColor),
          ),
          18.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.montserrat(
                    size: 16.sp,
                    color: AppColors.textPrimary,
                    weight: FontWeight.w800,
                  ),
                ),
                8.verticalSpace,
                Text(
                  'Wants to join ${request.circleName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.montserrat(
                    size: 11.sp,
                    color: AppColors.textSecondary,
                    weight: FontWeight.w400,
                  ),
                ),
                10.verticalSpace,
                Row(
                  children: [
                    StepsCircleJoinRequestButton(
                      label: isLoading ? 'Wait' : 'Accept',
                      selected: true,
                      onTap: isLoading ? null : onAccept,
                    ),
                    8.horizontalSpace,
                    StepsCircleJoinRequestButton(
                      label: 'Delete',
                      selected: false,
                      onTap: isLoading ? null : onDelete,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StepsCircleJoinRequestButton extends StatelessWidget {
  const StepsCircleJoinRequestButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.blueColor : AppColors.segmentTrack,
      borderRadius: BorderRadius.circular(18.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(18.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 7.h),
          child: Text(
            label,
            style: AppTextStyles.montserrat(
              size: 14.sp,
              color: selected ? Colors.white : AppColors.textSecondary,
              weight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

class DashboardThreatAlert extends StatelessWidget {
  const DashboardThreatAlert({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(10.w, 9.h, 12.w, 9.h),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F1),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: const Color(0xFFFF6E74), width: 1.5.w),
        boxShadow: [
          BoxShadow(
            color: const Color(0x1FFF5964),
            blurRadius: 12.r,
            offset: Offset(0, 3.h),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 8.w,
            height: 8.w,
            decoration: const BoxDecoration(
              color: Color(0xFFFF4E5C),
              shape: BoxShape.circle,
            ),
          ),
          9.horizontalSpace,
          Expanded(
            child: Text.rich(
              TextSpan(
                text: 'Territory under threat',
                style: AppTextStyles.inter(
                  size: 12,
                  color: const Color(0xFF111827),
                  weight: FontWeight.w800,
                  height: 1.18,
                ),
                children: [
                  TextSpan(
                    text:
                        ' — Rivera captured 3 tiles near your north edge 22 min ago',
                    style: AppTextStyles.inter(
                      size: 12,
                      color: const Color(0xFF111827),
                      weight: FontWeight.w500,
                      height: 1.18,
                    ),
                  ),
                ],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
