import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/widgets/shared/app_borders.dart';

class OverviewStatsSection extends StatelessWidget {
  const OverviewStatsSection({
    super.key,
    required this.distanceKm,
    required this.capturedArea,
    required this.selectedRangeIndex,
    required this.weekStart,
    required this.onRangeChanged,
    required this.onPreviousWeek,
    required this.onNextWeek,
  });

  final double distanceKm;
  final double capturedArea;
  final int selectedRangeIndex;
  final DateTime weekStart;
  final ValueChanged<int> onRangeChanged;
  final VoidCallback onPreviousWeek;
  final VoidCallback onNextWeek;

  @override
  Widget build(BuildContext context) {
    final displayDistance = math.max(distanceKm, 8.72);
    final displayArea = math.max(capturedArea, 12.6);

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
          selectedIndex: selectedRangeIndex,
          onChanged: onRangeChanged,
        ),
        13.verticalSpace,
        _WeekNavigator(
          weekStart: weekStart,
          onPrevious: onPreviousWeek,
          onNext: onNextWeek,
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
        _StatsCard(
          height: 188.h,
          child: _DistanceBarChart(distanceKm: displayDistance),
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
        _StatsCard(
          height: 250.h,
          padding: EdgeInsets.fromLTRB(8.w, 14.h, 12.w, 16.h),
          child: _TerritoryLineChart(capturedArea: displayArea),
        ),
      ],
    );
  }
}

class _StatsRangeTabs extends StatelessWidget {
  const _StatsRangeTabs({required this.selectedIndex, required this.onChanged});

  final int selectedIndex;
  final ValueChanged<int> onChanged;

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
          final selected = index == selectedIndex;

          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.horizontal(
                left: Radius.circular(index == 0 ? 18.r : 0),
                right: Radius.circular(index == labels.length - 1 ? 18.r : 0),
              ),
              onTap: () => onChanged(index),
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

class _WeekNavigator extends StatelessWidget {
  const _WeekNavigator({
    required this.weekStart,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime weekStart;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final weekEnd = weekStart.add(const Duration(days: 6));
    final sameMonth = weekStart.month == weekEnd.month;
    final formatter = DateFormat('MMM d');
    final endFormatter = sameMonth ? DateFormat('d') : DateFormat('MMM d');
    final label =
        '${formatter.format(weekStart)} - ${endFormatter.format(weekEnd)}';

    return Row(
      children: [
        _WeekArrowButton(icon: Icons.chevron_left_rounded, onTap: onPrevious),
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
        _WeekArrowButton(icon: Icons.chevron_right_rounded, onTap: onNext),
      ],
    );
  }
}

class _WeekArrowButton extends StatelessWidget {
  const _WeekArrowButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

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
          child: Icon(icon, size: 26.sp, color: Colors.black),
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
      padding: padding ?? EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: AppBorders.raised(),
        
      ),
      child: child,
    );
  }
}

class _DistanceBarChart extends StatelessWidget {
  const _DistanceBarChart({required this.distanceKm});

  final double distanceKm;

  @override
  Widget build(BuildContext context) {
    const values = [0.10, 0.78, 0.0, 1.08, 0.98, 0.62, 0.22];
    const labels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return LayoutBuilder(
      builder: (context, constraints) {
        final barHeight = constraints.maxHeight - 36.h;

        return Column(
          children: [
            SizedBox(
              height: barHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(values.length, (index) {
                      return Expanded(
                        child: Center(
                          child: values[index] == 0
                              ? const SizedBox.shrink()
                              : Container(
                                  width: 20.w,
                                  height: math.max(
                                    12.h,
                                    barHeight * values[index],
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD6E8FF),
                                    borderRadius: BorderRadius.circular(999.r),
                                  ),
                                ),
                        ),
                      );
                    }),
                  ),
                  Positioned(
                    left: constraints.maxWidth * 0.49,
                    top: 38.h,
                    child: _ChartTooltip(
                      title: '${distanceKm.toStringAsFixed(2)}km',
                      subtitle: '22:00min',
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: labels
                  .map(
                    (label) => Expanded(
                      child: Text(
                        label,
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
}

class _TerritoryLineChart extends StatelessWidget {
  const _TerritoryLineChart({required this.capturedArea});

  final double capturedArea;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: _TerritoryChartPainter(),
            ),
            Positioned(
              left: constraints.maxWidth * 0.44,
              top: constraints.maxHeight * 0.39,
              child: _ChartTooltip(
                title: '${capturedArea.toStringAsFixed(1)}km²',
              ),
            ),
          ],
        );
      },
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

class _TerritoryChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final left = 46.w;
    final right = 8.w;
    final top = 6.h;
    final bottom = 26.h;
    final chartWidth = size.width - left - right;
    final chartHeight = size.height - top - bottom;
    final labels = ['50km²', '20km²', '10km²', '5km²', '2km²', '0'];
    final labelY = [0.0, 0.22, 0.40, 0.57, 0.75, 1.0];
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
    );

    for (var i = 0; i < labels.length; i++) {
      textPainter.text = TextSpan(
        text: labels[i],
        style: TextStyle(
          color: const Color(0xFF374151),
          fontFamily: 'Inter',
          fontSize: 11.sp,
          fontWeight: FontWeight.w500,
        ),
      );
      textPainter.layout(maxWidth: left - 4.w);
      textPainter.paint(
        canvas,
        Offset(0, top + (chartHeight * labelY[i]) - (textPainter.height / 2)),
      );
    }

    final points = <Offset>[
      Offset(left + chartWidth * 0.00, top + chartHeight * 0.56),
      Offset(left + chartWidth * 0.14, top + chartHeight * 0.22),
      Offset(left + chartWidth * 0.34, top + chartHeight * 0.35),
      Offset(left + chartWidth * 0.50, top + chartHeight * 0.66),
      Offset(left + chartWidth * 0.67, top + chartHeight * 0.64),
      Offset(left + chartWidth * 0.80, top + chartHeight * 0.76),
      Offset(left + chartWidth * 0.96, top + chartHeight * 0.13),
    ];

    final line = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final midX = (p0.dx + p1.dx) / 2;
      line.cubicTo(midX, p0.dy, midX, p1.dy, p1.dx, p1.dy);
    }

    final fill = Path.from(line)
      ..lineTo(points.last.dx, top + chartHeight)
      ..lineTo(points.first.dx, top + chartHeight)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF7FB2FF).withValues(alpha: 0.38),
          const Color(0xFF7FB2FF).withValues(alpha: 0.02),
        ],
      ).createShader(Rect.fromLTWH(left, top, chartWidth, chartHeight));

    canvas.drawPath(fill, fillPaint);
    canvas.drawPath(
      line,
      Paint()
        ..color = const Color(0xFF4E6DFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5.w
        ..strokeCap = StrokeCap.round,
    );

    final dotPaint = Paint()..color = const Color(0xFF4E6DFF);
    for (final point in points) {
      canvas.drawCircle(point, 4.r, dotPaint);
    }

    const xLabels = ['S', 'M', 'Y', 'W', 'T', 'F', 'S'];
    for (var i = 0; i < xLabels.length; i++) {
      textPainter.text = TextSpan(
        text: xLabels[i],
        style: TextStyle(
          color: const Color(0xFF111827),
          fontFamily: 'Inter',
          fontSize: 13.sp,
          fontWeight: FontWeight.w500,
        ),
      );
      textPainter.layout();
      final x = left + chartWidth * (i / (xLabels.length - 1));
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, top + chartHeight + 12.h),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
