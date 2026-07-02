import 'package:flutter/material.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/features/leaderboard/models/leaderboard_participant.dart';
import 'package:test_steps/widgets/shared/dashboard_segmented_tab_bar.dart';

class LeaderboardScopeSwitcher extends StatelessWidget {
  const LeaderboardScopeSwitcher({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return DashboardSegmentedTabBar(
      labels: LeaderboardMetric.values.map((metric) => metric.label).toList(),
      selectedIndex: selectedIndex,
      onChanged: onChanged,
      height: 48,
      backgroundColor: AppColors.segmentTrack,
      inactiveTextColor: AppColors.textSecondary,
    );
  }
}
