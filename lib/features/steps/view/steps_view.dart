import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/features/steps/view/badges_tab_section.dart';
import 'package:test_steps/features/steps/view/objective_tab_section.dart';
import 'package:test_steps/features/profile/view/profile_view.dart';
import 'package:test_steps/features/steps/view/overview_stats_section.dart';
import 'package:test_steps/features/steps/widgets/steps_dashboard_tile.dart';
import 'package:test_steps/features/steps/widgets/steps_progress_painter.dart';
import 'package:test_steps/features/steps/view/territory_tab_section.dart';
import 'package:test_steps/screens/notifications_screen.dart';
import 'package:test_steps/services/health_service.dart';
import 'package:test_steps/widgets/shared/app_borders.dart';
import 'package:test_steps/widgets/shared/dashboard_screen_header.dart';
import 'package:test_steps/widgets/shared/dashboard_tab_button.dart';

class StepsView extends ConsumerStatefulWidget {
  const StepsView({super.key});

  @override
  ConsumerState<StepsView> createState() => _StepsViewState();
}

class _StepsViewState extends ConsumerState<StepsView> {
  int _selectedDashboardTab = 0;
  int _selectedStatsRange = 0;
  DateTime _visibleWeekStart = DateTime(2026, 5, 10);

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(stepProvider.notifier).loadWeeklySteps());
  }

  final tabs = [
    ('Overview', null),
    ('Territory', 5),
    ('Objective', 5),
    ('Badges', null),
  ];

  @override
  Widget build(BuildContext context) {
    final stepState = ref.watch(stepProvider);
    final numberFormat = NumberFormat.decimalPattern();
    final goal = stepState.stepGoal > 0 ? stepState.stepGoal : 10000;
    final progress = (stepState.steps / goal).clamp(0.0, 1.0);
    final totalArea = (stepState.distanceKm * 0.28).clamp(0.1, 99.9);
    final minutes = math.max(1, (stepState.steps / 1160).round());
    final duration =
        '${minutes ~/ 60}:${(minutes % 60).toString().padLeft(2, '0')}:39';
    final summaryItems = [
      ('${stepState.distanceKm.toStringAsFixed(2)}km', 'Total Distance'),
      (duration, 'Duration'),
      ('${totalArea.toStringAsFixed(1)} km²', 'Total Area'),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
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
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 28.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DashboardScreenHeader(
                    title: 'Home',
                    energy: stepState.attackEnergy,
                    onNotificationsTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      );
                    },
                    onProfileTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ProfileView()),
                      );
                    },
                  ),
                  18.verticalSpace,
                  if (_selectedDashboardTab == 2)
                    const ObjectiveEnergyHeader()
                  else
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 16.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDDEBFF),
                        borderRadius: BorderRadius.circular(22.r),
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
                                          size: 18,
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
                  16.verticalSpace,
                  const DashboardThreatAlert(),
                  18.verticalSpace,
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: tabs.map((tab) {
                        final index = tabs.indexOf(tab);
                        final selected = _selectedDashboardTab == index;

                        return Padding(
                          padding: EdgeInsets.only(right: 6.w),
                          child: DashboardTabButton(
                            label: tab.$1,
                            count: tab.$2,
                            selected: selected,
                            onTap: () {
                              setState(() => _selectedDashboardTab = index);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  18.verticalSpace,
                  if (_selectedDashboardTab == 0) ...[
                    Container(
                      width: double.infinity,

                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 16.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20.r),
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
                                      size: 14.sp,
                                      color: AppColors.textPrimary,
                                      weight: FontWeight.w400,
                                    ),
                                  ),
                                  8.verticalSpace,
                                  Text(
                                    numberFormat.format(stepState.steps),
                                    style: AppTextStyles.montserrat(
                                      size: 20.sp,
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
                              width: 150.w,
                              height: 80.h,
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
                    16.verticalSpace,
                    GridView(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10.w,
                        mainAxisSpacing: 10.h,
                        childAspectRatio: 0.96,
                      ),
                      children: [
                        StepsDashboardTile(
                          title: 'Today Kcal Burned',
                          value: numberFormat.format(stepState.calories),
                          icon: 'assets/icons/battery.svg',
                          iconColor: const Color(0xFF5397FF),
                          iconBackgroundColor: const Color(0xFFD8E9FF),
                          footer: '18+ since last week',
                          footerIcon: Icons.arrow_upward_rounded,
                          footerIconColor: const Color(0xFF11BBAE),
                        ),
                        StepsDashboardTile(
                          title: 'Heart Rate',
                          value: '82',
                          unit: 'bpm',
                          icon: 'assets/icons/walk.svg',
                          iconColor: const Color(0xFFEF8E45),
                          iconBackgroundColor: const Color(0xFFE0F0FF),
                          footer: '18+ since last week',
                          footerIcon: Icons.arrow_upward_rounded,
                          footerIconColor: const Color(0xFF11BBAE),
                        ),
                        StepsDashboardTile(
                          title: 'Streak',
                          value: '${stepState.weeklyStreak}',
                          unit: 'days',
                          icon: 'assets/icons/streak.svg',
                          iconColor: const Color(0xFFFF7A1A),
                          iconBackgroundColor: const Color(0xFFDDEBFF),
                          footer: 'Personal best',
                        ),
                        StepsDashboardTile(
                          title: 'Today Energy',
                          value: '${stepState.attackEnergy}',
                          icon: 'assets/icons/energy.svg',
                          iconColor: Colors.white,
                          iconBackgroundColor: const Color(0xFF20D83A),
                          footer: '9- since last week',
                          footerIcon: Icons.arrow_downward_rounded,
                          footerIconColor: const Color(0xFFE23A3A),
                        ),
                      ],
                    ),
                    22.verticalSpace,
                    OverviewStatsSection(
                      distanceKm: stepState.distanceKm,
                      capturedArea: totalArea,
                      selectedRangeIndex: _selectedStatsRange,
                      weekStart: _visibleWeekStart,
                      onRangeChanged: (index) {
                        setState(() => _selectedStatsRange = index);
                      },
                      onPreviousWeek: () {
                        setState(
                          () => _visibleWeekStart = _visibleWeekStart.subtract(
                            const Duration(days: 7),
                          ),
                        );
                      },
                      onNextWeek: () {
                        setState(
                          () => _visibleWeekStart = _visibleWeekStart.add(
                            const Duration(days: 7),
                          ),
                        );
                      },
                    ),
                  ] else if (_selectedDashboardTab == 1)
                    TerritoryTabSection(
                      onViewMap: () {},
                      onHistoryTap: () {},
                      onViewTerritory: () {},
                    )
                  else if (_selectedDashboardTab == 2)
                    ObjectiveTabSection(
                      steps: stepState.steps,
                      onObjectiveTap: () {},
                    )
                  else
                    BadgesTabSection(
                      onSearchTap: () {},
                      onFilterTap: () {},
                      onBadgeTap: (_) {},
                    ),
                ],
              ),
            ),
          ),
        ],
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
