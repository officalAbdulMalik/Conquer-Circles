import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_spacing.dart';
import 'package:test_steps/features/profile/widgets/profile_stats/profile_stats_breakdown_card.dart';
import 'package:test_steps/features/profile/widgets/profile_stats/profile_stats_header.dart';
import 'package:test_steps/features/profile/widgets/profile_stats/profile_stats_models.dart';
import 'package:test_steps/features/profile/widgets/profile_stats/profile_stats_range_switch.dart';
import 'package:test_steps/features/profile/widgets/profile_stats/profile_stats_summary_grid.dart';
import 'package:test_steps/features/profile/widgets/profile_stats/profile_stats_tabs.dart';
import 'package:test_steps/features/profile/widgets/profile_stats/profile_stats_trend_card.dart';

class ProfileStatsView extends StatefulWidget {
  const ProfileStatsView({super.key});

  @override
  State<ProfileStatsView> createState() => _ProfileStatsViewState();
}

class _ProfileStatsViewState extends State<ProfileStatsView> {
  bool isWeekly = true;
  int selectedTab = 0;

  final List<ProfileTopStatTab> tabs = const [
    ProfileTopStatTab(icon: Icons.directions_walk_outlined, label: 'Steps'),
    ProfileTopStatTab(icon: Icons.local_fire_department_outlined, label: 'Calories'),
    ProfileTopStatTab(icon: Icons.favorite_border_rounded, label: 'Heart Rate'),
    ProfileTopStatTab(icon: Icons.location_on_outlined, label: 'Distance'),
  ];

  final List<ProfileMetricData> metrics = const [
    ProfileMetricData(
      unit: 'steps',
      yAxisMax: 14000,
      decimalPlaces: 0,
      changePercent: 9,
      weekly: [7200, 9800, 6400, 11200, 8900, 12400, 8547],
      monthly: [6600, 9100, 7100, 10400, 9600, 11800, 8200],
    ),
    ProfileMetricData(
      unit: 'kcal',
      yAxisMax: 800,
      decimalPlaces: 0,
      changePercent: 6,
      weekly: [420, 580, 390, 620, 510, 700, 475],
      monthly: [390, 540, 430, 600, 560, 670, 440],
    ),
    ProfileMetricData(
      unit: 'bpm',
      yAxisMax: 160,
      decimalPlaces: 0,
      changePercent: 3,
      weekly: [88, 94, 86, 102, 91, 108, 93],
      monthly: [85, 90, 87, 99, 95, 104, 89],
    ),
    ProfileMetricData(
      unit: 'km',
      yAxisMax: 12,
      decimalPlaces: 1,
      changePercent: 11,
      weekly: [4.8, 7.1, 4.2, 8.9, 6.4, 10.3, 5.9],
      monthly: [4.2, 6.6, 5.1, 8.1, 7.2, 9.6, 5.4],
    ),
  ];

  final List<String> days = const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final metric = metrics[selectedTab];
    final values = isWeekly ? metric.weekly : metric.monthly;
    final total = values.reduce((a, b) => a + b);
    final average = total / values.length;
    final peak = values.reduce((a, b) => a > b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final maxChartValue = metric.yAxisMax > maxValue ? metric.yAxisMax : maxValue;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              ProfileStatsHeader(onBack: () => Navigator.of(context).pop()),
              Transform.translate(
                offset: Offset(0, -16.h),
                child: Padding(
                  padding: AppSpacing.pagePadding,
                  child: Column(
                    children: [
                      ProfileStatsTabs(
                        tabs: tabs,
                        selectedIndex: selectedTab,
                        onTabSelected: (index) => setState(() => selectedTab = index),
                      ),
                      14.verticalSpace,
                      ProfileStatsRangeSwitch(
                        isWeekly: isWeekly,
                        onChanged: (value) => setState(() => isWeekly = value),
                      ),
                      14.verticalSpace,
                      ProfileStatsSummaryGrid(
                        averageValue: formatProfileMetricValue(average, metric),
                        peakValue: formatProfileMetricValue(peak, metric),
                        totalValue: formatProfileMetricValue(total, metric),
                        unit: metric.unit,
                        changePercent: metric.changePercent,
                      ),
                      14.verticalSpace,
                      ProfileStatsTrendCard(
                        values: values,
                        days: days,
                        maxValue: maxChartValue,
                        metricTitle: tabs[selectedTab].label,
                        metric: metric,
                      ),
                      14.verticalSpace,
                      ProfileStatsBreakdownCard(
                        values: values,
                        maxValue: maxChartValue,
                        days: days,
                        metric: metric,
                      ),
                      24.verticalSpace,
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
