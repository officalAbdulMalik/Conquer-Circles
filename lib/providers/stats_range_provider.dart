import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/legacy.dart';

import 'package:test_steps/models/dashboard_model.dart';
import 'package:test_steps/services/dashboard_service.dart';

/// Dashboard stats period selection (range + anchor) plus all the period
/// math and graph-loading orchestration that used to live in StepsView.
class StatsRangeState {
  StatsRangeState({
    this.range = DashboardStatsRange.week,
    DateTime? anchor,
  }) : anchor = anchor ?? _todayFloor();

  final DashboardStatsRange range;
  final DateTime anchor;

  static DateTime _todayFloor() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime get today => _todayFloor();

  DateTime get periodStart {
    switch (range) {
      case DashboardStatsRange.week:
        return anchor.subtract(Duration(days: anchor.weekday % DateTime.sunday));
      case DashboardStatsRange.month:
        return DateTime(anchor.year, anchor.month);
      case DashboardStatsRange.year:
        return DateTime(anchor.year);
      case DashboardStatsRange.allTime:
        return today;
    }
  }

  DateTime get fullPeriodEnd {
    switch (range) {
      case DashboardStatsRange.week:
        return periodStart.add(const Duration(days: 6));
      case DashboardStatsRange.month:
        return DateTime(anchor.year, anchor.month + 1, 0);
      case DashboardStatsRange.year:
        return DateTime(anchor.year, 12, 31);
      case DashboardStatsRange.allTime:
        return today;
    }
  }

  DateTime get periodEnd {
    final end = fullPeriodEnd;
    return end.isAfter(today) ? today : end;
  }

  bool get canNavigateNext {
    if (range == DashboardStatsRange.allTime) return false;
    return fullPeriodEnd.isBefore(today);
  }

  StatsRangeState copyWith({DashboardStatsRange? range, DateTime? anchor}) {
    return StatsRangeState(
      range: range ?? this.range,
      anchor: anchor ?? this.anchor,
    );
  }
}

class StatsRangeNotifier extends StateNotifier<StatsRangeState> {
  StatsRangeNotifier(this._ref) : super(StatsRangeState());

  final Ref _ref;

  Future<void> loadStatsGraph() async {
    final notifier = _ref.read(dashboardProvider.notifier);
    final allTime = state.range == DashboardStatsRange.allTime;
    await Future.wait([
      notifier.loadDistanceGraph(
        from: allTime ? null : state.periodStart,
        to: state.periodEnd,
        allTime: allTime,
      ),
      notifier.loadTerritoryGraph(
        from: allTime ? null : state.periodStart,
        to: state.periodEnd,
        allTime: allTime,
      ),
    ]);
  }

  Future<void> selectRange(DashboardStatsRange range) async {
    if (state.range == range) return;
    state = StatsRangeState(range: range);
    await loadStatsGraph();
  }

  Future<void> changePeriod(int direction) async {
    if (state.range == DashboardStatsRange.allTime) return;
    if (direction > 0 && !state.canNavigateNext) return;

    final anchor = state.anchor;
    late final DateTime next;
    switch (state.range) {
      case DashboardStatsRange.week:
        next = anchor.add(Duration(days: 7 * direction));
      case DashboardStatsRange.month:
        next = DateTime(anchor.year, anchor.month + direction);
      case DashboardStatsRange.year:
        next = DateTime(anchor.year + direction);
      case DashboardStatsRange.allTime:
        return;
    }
    state = state.copyWith(anchor: next);
    await loadStatsGraph();
  }
}

final statsRangeProvider =
    StateNotifierProvider<StatsRangeNotifier, StatsRangeState>(
  (ref) => StatsRangeNotifier(ref),
);
