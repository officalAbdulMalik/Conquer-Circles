import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/models/dashboard_model.dart';
import 'package:test_steps/widgets/shared/app_borders.dart';
import 'package:test_steps/widgets/shared/app_shimmer.dart';

class OverviewStatsSection extends StatelessWidget {
  const OverviewStatsSection({
    super.key,
    required this.distanceDays,
    required this.isDistanceLoading,
    required this.distanceError,
    required this.territoryDays,
    required this.isTerritoryLoading,
    required this.territoryError,
    required this.selectedRange,
    required this.periodStart,
    required this.periodEnd,
    required this.canNavigatePrevious,
    required this.canNavigateNext,
    required this.onRangeChanged,
    required this.onPreviousPeriod,
    required this.onNextPeriod,
    required this.onRetryDistance,
  });

  final List<DashboardDistanceDay> distanceDays;
  final bool isDistanceLoading;
  final String? distanceError;
  final List<DashboardTerritoryDay> territoryDays;
  final bool isTerritoryLoading;
  final String? territoryError;
  final DashboardStatsRange selectedRange;
  final DateTime periodStart;
  final DateTime periodEnd;
  final bool canNavigatePrevious;
  final bool canNavigateNext;
  final ValueChanged<DashboardStatsRange> onRangeChanged;
  final VoidCallback onPreviousPeriod;
  final VoidCallback onNextPeriod;
  final VoidCallback onRetryDistance;

  @override
  Widget build(BuildContext context) {
    final points = _distancePoints();
    final territoryPoints = _territoryPoints();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'States Overview',
          style: AppTextStyles.montserrat(
            size: 16.sp,
            color: const Color(0xFF101623),
            weight: FontWeight.w700,
          ),
        ),
        14.verticalSpace,
        _StatsRangeTabs(
          selectedRange: selectedRange,
          onChanged: onRangeChanged,
        ),
        13.verticalSpace,
        _PeriodNavigator(
          label: _periodLabel(),
          canGoPrevious: canNavigatePrevious,
          canGoNext: canNavigateNext,
          onPrevious: onPreviousPeriod,
          onNext: onNextPeriod,
        ),
        14.verticalSpace,
        Text(
          'Total Distance',
          style: AppTextStyles.montserrat(
            size: 14.sp,
            color: const Color(0xFF111827),
            weight: FontWeight.w700,
          ),
        ),
        12.verticalSpace,
        _DistanceGraphCard(
          points: points,
          isLoading: isDistanceLoading,
          error: distanceError,
          onRetry: onRetryDistance,
        ),
        16.verticalSpace,
        Text(
          'Total Capture Territory',
          style: AppTextStyles.montserrat(
            size: 14.sp,
            color: const Color(0xFF111827),
            weight: FontWeight.w700,
          ),
        ),
        12.verticalSpace,
        _TerritoryGraphCard(
          points: territoryPoints,
          isLoading: isTerritoryLoading,
          error: territoryError,
          onRetry: onRetryDistance,
        ),
      ],
    );
  }

  List<DashboardDistancePoint> _distancePoints() {
    switch (selectedRange) {
      case DashboardStatsRange.week:
        return distanceDays
            .map(
              (day) => DashboardDistancePoint(
                label: day.dayLabel,
                steps: day.steps,
                distanceKm: day.distanceKm,
                durationSeconds: day.durationSeconds,
              ),
            )
            .toList();
      case DashboardStatsRange.month:
        final bucketCount = ((periodEnd.day - 1) ~/ 7) + 1;
        return List.generate(bucketCount, (index) {
          final bucketDays = distanceDays.where(
            (day) => ((day.date.day - 1) ~/ 7) == index,
          );
          return _sumPoint('W${index + 1}', bucketDays);
        });
      case DashboardStatsRange.year:
        return List.generate(periodEnd.month, (index) {
          final month = index + 1;
          final monthDays = distanceDays.where(
            (day) => day.date.month == month,
          );
          return _sumPoint(
            DateFormat.MMM().format(DateTime(2020, month)),
            monthDays,
          );
        });
      case DashboardStatsRange.allTime:
        if (distanceDays.isEmpty) return const [];
        final firstYear = distanceDays.first.date.year;
        final lastYear = distanceDays.last.date.year;
        return List.generate(lastYear - firstYear + 1, (index) {
          final year = firstYear + index;
          final yearDays = distanceDays.where((day) => day.date.year == year);
          return _sumPoint(year.toString(), yearDays);
        });
    }
  }

  DashboardDistancePoint _sumPoint(
    String label,
    Iterable<DashboardDistanceDay> days,
  ) {
    var steps = 0;
    var distanceKm = 0.0;
    var durationSeconds = 0;
    for (final day in days) {
      steps += day.steps;
      distanceKm += day.distanceKm;
      durationSeconds += day.durationSeconds;
    }
    return DashboardDistancePoint(
      label: label,
      steps: steps,
      distanceKm: distanceKm,
      durationSeconds: durationSeconds,
    );
  }

  List<DashboardTerritoryPoint> _territoryPoints() {
    switch (selectedRange) {
      case DashboardStatsRange.week:
        return territoryDays
            .map(
              (day) => DashboardTerritoryPoint(
                label: day.dayLabel,
                areaKm2: day.areaKm2,
              ),
            )
            .toList();
      case DashboardStatsRange.month:
        final bucketCount = ((periodEnd.day - 1) ~/ 7) + 1;
        return List.generate(bucketCount, (index) {
          final area = territoryDays
              .where((day) => ((day.date.day - 1) ~/ 7) == index)
              .fold<double>(0, (sum, day) => sum + day.areaKm2);
          return DashboardTerritoryPoint(label: 'W${index + 1}', areaKm2: area);
        });
      case DashboardStatsRange.year:
        return List.generate(periodEnd.month, (index) {
          final month = index + 1;
          final area = territoryDays
              .where((day) => day.date.month == month)
              .fold<double>(0, (sum, day) => sum + day.areaKm2);
          return DashboardTerritoryPoint(
            label: DateFormat.MMM().format(DateTime(2020, month)),
            areaKm2: area,
          );
        });
      case DashboardStatsRange.allTime:
        if (territoryDays.isEmpty) return const [];
        final firstYear = territoryDays.first.date.year;
        final lastYear = territoryDays.last.date.year;
        return List.generate(lastYear - firstYear + 1, (index) {
          final year = firstYear + index;
          final area = territoryDays
              .where((day) => day.date.year == year)
              .fold<double>(0, (sum, day) => sum + day.areaKm2);
          return DashboardTerritoryPoint(label: year.toString(), areaKm2: area);
        });
    }
  }

  String _periodLabel() {
    switch (selectedRange) {
      case DashboardStatsRange.week:
        final sameMonth = periodStart.month == periodEnd.month;
        final start = DateFormat('MMM d').format(periodStart);
        final end = sameMonth
            ? DateFormat('d').format(periodEnd)
            : DateFormat('MMM d').format(periodEnd);
        return '$start - $end';
      case DashboardStatsRange.month:
        return DateFormat('MMMM yyyy').format(periodStart);
      case DashboardStatsRange.year:
        return DateFormat('yyyy').format(periodStart);
      case DashboardStatsRange.allTime:
        return 'All Time';
    }
  }
}

class _StatsRangeTabs extends StatelessWidget {
  const _StatsRangeTabs({required this.selectedRange, required this.onChanged});

  final DashboardStatsRange selectedRange;
  final ValueChanged<DashboardStatsRange> onChanged;

  @override
  Widget build(BuildContext context) {
    const labels = ['Week', 'Month', 'Year', 'All Time'];

    return Container(
      height: 36.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: const Color(0xFFE1E6EF), width: 1.w),
      ),
      child: Row(
        children: List.generate(labels.length, (index) {
          final range = DashboardStatsRange.values[index];
          final selected = range == selectedRange;

          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.horizontal(
                left: Radius.circular(index == 0 ? 18.r : 0),
                right: Radius.circular(index == labels.length - 1 ? 18.r : 0),
              ),
              onTap: () => onChanged(range),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF526BFF)
                      : Colors.transparent,
                  borderRadius: BorderRadius.horizontal(
                    left: Radius.circular(index == 0 ? 18.r : 0),
                    right: Radius.circular(
                      index == labels.length - 1 ? 18.r : 0,
                    ),
                  ),
                  border: index == 0
                      ? null
                      : const Border(
                          left: BorderSide(color: Color(0xFFE1E6EF)),
                        ),
                ),
                child: Text(
                  labels[index],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.montserrat(
                    size: 14.sp,
                    color: selected ? Colors.white : AppColors.textNavy,
                    weight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _PeriodNavigator extends StatelessWidget {
  const _PeriodNavigator({
    required this.label,
    required this.canGoPrevious,
    required this.canGoNext,
    required this.onPrevious,
    required this.onNext,
  });

  final String label;
  final bool canGoPrevious;
  final bool canGoNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _PeriodArrowButton(
          icon: Icons.chevron_left_rounded,
          onTap: canGoPrevious ? onPrevious : null,
        ),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.montserrat(
              size: 14.sp,
              color: const Color(0xFF111827),
              weight: FontWeight.w600,
            ),
          ),
        ),
        _PeriodArrowButton(
          icon: Icons.chevron_right_rounded,
          onTap: canGoNext ? onNext : null,
        ),
      ],
    );
  }
}

class _PeriodArrowButton extends StatelessWidget {
  const _PeriodArrowButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 36.w,
          height: 32.h,
          child: Icon(
            icon,
            size: 26.sp,
            color: onTap == null ? AppColors.textMuted : Colors.black,
          ),
        ),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.child, required this.height, this.padding});

  final Widget child;
  final double height;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      padding:
          padding ?? EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: AppBorders.raised(),
      ),
      child: child,
    );
  }
}

class _DistanceGraphCard extends StatelessWidget {
  const _DistanceGraphCard({
    required this.points,
    required this.isLoading,
    required this.error,
    required this.onRetry,
  });

  final List<DashboardDistancePoint> points;
  final bool isLoading;
  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 195.h,
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: AppBorders.raised(),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: isLoading
            ? const _DistanceGraphLoading()
            : error != null
            ? _DistanceGraphError(onRetry: onRetry)
            : _DistanceBarChart(points: points),
      ),
    );
  }
}

class _DistanceGraphLoading extends StatelessWidget {
  const _DistanceGraphLoading();

  @override
  Widget build(BuildContext context) {
    const barHeights = [42.0, 94.0, 66.0, 126.0, 108.0, 76.0, 48.0];

    return AppShimmer(
      key: ValueKey('distance-graph-loading'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(barHeights.length, (index) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 7.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 24.w,
                    height: barHeights[index].h,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8EDF5),
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  10.verticalSpace,
                  Container(
                    width: 18.w,
                    height: 12.h,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8EDF5),
                      borderRadius: BorderRadius.circular(5.r),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _DistanceBarChart extends StatefulWidget {
  const _DistanceBarChart({required this.points});

  final List<DashboardDistancePoint> points;

  @override
  State<_DistanceBarChart> createState() => _DistanceBarChartState();
}

class _DistanceBarChartState extends State<_DistanceBarChart> {
  /// Selected bar (tooltip) — ValueNotifier so hover/tap rebuilds only the
  /// chart, without a setState pass over the whole stats section.
  final ValueNotifier<int?> _selectedIndexNotifier = ValueNotifier(null);

  @override
  void didUpdateWidget(covariant _DistanceBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    final selected = _selectedIndexNotifier.value;
    if (selected != null && selected >= widget.points.length) {
      _selectedIndexNotifier.value = null;
    }
  }

  @override
  void dispose() {
    _selectedIndexNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int?>(
      valueListenable: _selectedIndexNotifier,
      builder: (context, selected, _) => _buildChart(context, selected),
    );
  }

  Widget _buildChart(BuildContext context, int? _selectedIndex) {
    final points = widget.points;
    final maxDistance = points.fold<double>(
      0,
      (maximum, point) => math.max(maximum, point.distanceKm),
    );
    final normalizedValues = maxDistance <= 0
        ? List<double>.filled(points.length, 0)
        : points.map((point) => point.distanceKm / maxDistance).toList();
    final selectedIndex =
        _selectedIndex != null && _selectedIndex < points.length
        ? _selectedIndex
        : null;
    final selectedPoint = selectedIndex == null ? null : points[selectedIndex];

    return LayoutBuilder(
      builder: (context, constraints) {
        final barHeight = constraints.maxHeight - 36.h;
        final itemWidth = points.isEmpty
            ? constraints.maxWidth
            : constraints.maxWidth / points.length;
        final tooltipWidth = 116.w;
        final tooltipLeft = selectedIndex == null
            ? 0.0
            : ((itemWidth * selectedIndex) +
                      (itemWidth / 2) -
                      (tooltipWidth / 2))
                  .clamp(
                    0.0,
                    math.max(0.0, constraints.maxWidth - tooltipWidth),
                  )
                  .toDouble();

        return Column(
          children: [
            SizedBox(
              height: barHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(normalizedValues.length, (index) {
                      return Expanded(
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          onEnter: (_) => _select(index),
                          onExit: (_) {
                            if (_selectedIndex == index) _clearSelection();
                          },
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _toggleSelection(index),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: normalizedValues[index] == 0
                                  ? Container(
                                      width: 20.w,
                                      height: 8.h,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE8F1FF),
                                        borderRadius: BorderRadius.circular(
                                          999.r,
                                        ),
                                      ),
                                    )
                                  : AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 140,
                                      ),
                                      width: 20.w,
                                      height: math.max(
                                        12.h,
                                        barHeight * normalizedValues[index],
                                      ),
                                      decoration: BoxDecoration(
                                        color: _selectedIndex == index
                                            ? const Color(0xFFAFCFFF)
                                            : const Color(0xFFD6E8FF),
                                        borderRadius: BorderRadius.circular(
                                          999.r,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  if (selectedPoint != null)
                    Positioned(
                      left: tooltipLeft,
                      top: 54.h,
                      child: IgnorePointer(
                        child: SizedBox(
                          width: tooltipWidth,
                          child: _ChartTooltip(
                            title:
                                '${selectedPoint.distanceKm.toStringAsFixed(2)}km',
                            subtitle: _formatDuration(
                              selectedPoint.durationSeconds,
                            ),
                          ),
                        ),
                      ),
                    )
                  else if (points.every((point) => point.distanceKm <= 0))
                    Center(
                      child: IgnorePointer(
                        child: Text(
                          'No distance recorded',
                          style: AppTextStyles.montserrat(
                            size: 13.sp,
                            color: AppColors.textSecondary,
                            weight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Row(
              children: points
                  .map(
                    (point) => Expanded(
                      child: Text(
                        point.label,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.montserrat(
                          size: 13.sp,
                          color: const Color(0xFF111827),
                          weight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        );
      },
    );
  }

  void _select(int index) {
    _selectedIndexNotifier.value = index;
  }

  void _clearSelection() {
    _selectedIndexNotifier.value = null;
  }

  void _toggleSelection(int index) {
    _selectedIndexNotifier.value =
        _selectedIndexNotifier.value == index ? null : index;
  }

  String _formatDuration(int seconds) {
    if (seconds <= 0) return '0:00min';
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}min';
  }
}

class _DistanceGraphError extends StatelessWidget {
  const _DistanceGraphError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Could not load graph data',
            style: AppTextStyles.montserrat(
              size: 13.sp,
              color: AppColors.textSecondary,
              weight: FontWeight.w500,
            ),
          ),
          4.verticalSpace,
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _ChartTooltip extends StatelessWidget {
  const _ChartTooltip({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0x1A0F172A),
            blurRadius: 16.r,
            offset: Offset(0, 6.h),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: AppTextStyles.montserrat(
              size: 13.sp,
              color: const Color(0xFF0A0F1A),
              weight: FontWeight.w700,
            ),
          ),
          if (subtitle != null) ...[
            5.verticalSpace,
            Text(
              subtitle!,
              style: AppTextStyles.montserrat(
                size: 11.sp,
                color: const Color(0xFF6B7280),
                weight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TerritoryGraphCard extends StatelessWidget {
  const _TerritoryGraphCard({
    required this.points,
    required this.isLoading,
    required this.error,
    required this.onRetry,
  });

  final List<DashboardTerritoryPoint> points;
  final bool isLoading;
  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _StatsCard(
      height: 250.h,
      padding: EdgeInsets.fromLTRB(8.w, 14.h, 12.w, 16.h),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: isLoading
            ? const _TerritoryGraphLoading()
            : error != null
            ? _DistanceGraphError(onRetry: onRetry)
            : _TerritoryLineChart(points: points),
      ),
    );
  }
}

class _TerritoryGraphLoading extends StatelessWidget {
  const _TerritoryGraphLoading();

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      key: const ValueKey('territory-graph-loading'),
      child: CustomPaint(
        painter: _TerritoryLoadingPainter(),
        size: Size.infinite,
      ),
    );
  }
}

class _TerritoryLineChart extends StatelessWidget {
  const _TerritoryLineChart({required this.points});

  final List<DashboardTerritoryPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return Center(
        child: Text(
          'No captured territory in this period',
          style: AppTextStyles.montserrat(
            size: 13.sp,
            color: AppColors.textSecondary,
            weight: FontWeight.w500,
          ),
        ),
      );
    }

    final maxArea = points.fold<double>(
      0,
      (maximum, point) => math.max(maximum, point.areaKm2),
    );
    final chartMax = _niceChartMaximum(maxArea);

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: math.max(points.length - 1, 1).toDouble(),
        minY: 0,
        maxY: chartMax,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => Colors.white,
            tooltipBorderRadius: BorderRadius.circular(14.r),
            tooltipPadding: EdgeInsets.symmetric(
              horizontal: 13.w,
              vertical: 10.h,
            ),
            tooltipBorder: const BorderSide(color: Color(0xFFE8EDF5)),
            getTooltipItems: (spots) => spots.map((spot) {
              final point = points[spot.x.round()];
              return LineTooltipItem(
                '${point.areaKm2.toStringAsFixed(2)}km²',
                AppTextStyles.montserrat(
                  size: 13.sp,
                  color: const Color(0xFF0A0F1A),
                  weight: FontWeight.w700,
                ),
              );
            }).toList(),
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 47.w,
              interval: chartMax / 5,
              getTitlesWidget: (value, meta) => Text(
                value == 0 ? '0' : '${_compactArea(value)}km²',
                style: AppTextStyles.montserrat(
                  size: 10.sp,
                  color: const Color(0xFF374151),
                  weight: FontWeight.w500,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 25.h,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.round();
                if (index < 0 || index >= points.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: EdgeInsets.only(top: 7.h),
                  child: Text(
                    points[index].label,
                    style: AppTextStyles.montserrat(
                      size: 12.sp,
                      color: const Color(0xFF111827),
                      weight: FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              points.length,
              (index) => FlSpot(index.toDouble(), points[index].areaKm2),
            ),
            isCurved: true,
            curveSmoothness: 0.32,
            color: const Color(0xFF526BFF),
            barWidth: 2.2.w,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(
                    radius: 4.r,
                    color: const Color(0xFF526BFF),
                    strokeWidth: 0,
                  ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF8FB8F4).withValues(alpha: 0.36),
                  const Color(0xFF8FB8F4).withValues(alpha: 0.05),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _niceChartMaximum(double value) {
    if (value <= 0) return 5;
    final magnitude = math.pow(10, (math.log(value) / math.ln10).floor());
    return (value / magnitude).ceil() * magnitude.toDouble();
  }

  String _compactArea(double value) {
    if (value >= 10 || value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }
}

class _TerritoryLoadingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE8EDF5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    final path = Path()
      ..moveTo(48, size.height * 0.7)
      ..cubicTo(
        size.width * 0.25,
        size.height * 0.2,
        size.width * 0.42,
        size.height * 0.8,
        size.width * 0.58,
        size.height * 0.55,
      )
      ..cubicTo(
        size.width * 0.72,
        size.height * 0.85,
        size.width * 0.84,
        size.height * 0.25,
        size.width - 10,
        size.height * 0.35,
      );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
