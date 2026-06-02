import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/models/walk_models.dart';

class RunSessionSummaryPanel extends StatefulWidget {
  const RunSessionSummaryPanel({
    super.key,
    required this.startedAt,
    required this.pausedAt,
    required this.distanceKm,
    required this.totalAreaKm2,
    required this.isPaused,
    required this.onPause,
    required this.onResume,
    required this.onFinish,
    this.territories = const [],
    this.onTerritoryTap,
  });

  final DateTime? startedAt;
  final DateTime? pausedAt;
  final double distanceKm;
  final double totalAreaKm2;
  final bool isPaused;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onFinish;
  final List<Territory> territories;
  final ValueChanged<Territory>? onTerritoryTap;

  @override
  State<RunSessionSummaryPanel> createState() => _RunSessionSummaryPanelState();
}

class _RunSessionSummaryPanelState extends State<RunSessionSummaryPanel> {
  Timer? _ticker;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timerEnd = widget.isPaused ? widget.pausedAt ?? _now : _now;
    final elapsed = widget.startedAt == null
        ? Duration.zero
        : timerEnd.difference(widget.startedAt!);

    return DraggableScrollableSheet(
      initialChildSize: widget.isPaused ? 0.36 : 0.34,
      minChildSize: widget.isPaused ? 0.34 : 0.32,
      maxChildSize: 0.42,
      snap: true,
      snapSizes: widget.isPaused ? const [0.36, 0.42] : const [0.34, 0.42],
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 24,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: CustomScrollView(
              controller: scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 49,
                          height: 5,
                          margin: EdgeInsets.only(bottom: 14.h),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD9DCE4),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                        _StatsCard(
                          area: _formatArea(widget.totalAreaKm2),
                          distance: _formatDistance(widget.distanceKm),
                          duration: _formatDuration(elapsed),
                          pace: _formatPace(elapsed, widget.distanceKm),
                        ),
                        SizedBox(height: 20.h),
                        widget.isPaused
                            ? _PausedRunActions(
                                onResume: widget.onResume,
                                onFinish: widget.onFinish,
                              )
                            : _PauseRunButton(onTap: widget.onPause),
                        SizedBox(height: 14.h),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatArea(double value) {
    if (value <= 0) return '0km²';
    return '${value.toStringAsFixed(value < 10 ? 2 : 1)}km²';
  }

  String _formatDistance(double value) {
    if (value <= 0) return '0km';
    return '${value.toStringAsFixed(value < 10 ? 2 : 1)}km';
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hours = duration.inHours;

    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  String _formatPace(Duration elapsed, double distanceKm) {
    if (distanceKm <= 0) return '0/km';

    final secondsPerKm = elapsed.inSeconds / distanceKm;
    final minutes = secondsPerKm ~/ 60;
    final seconds = (secondsPerKm % 60).round().toString().padLeft(2, '0');
    return '$minutes:$seconds/km';
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({
    required this.area,
    required this.distance,
    required this.duration,
    required this.pace,
  });

  final String area;
  final String distance;
  final String duration;
  final String pace;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 16.h),
      decoration: BoxDecoration(
        color: const Color(0xFFDCEBFF),
        borderRadius: BorderRadius.circular(24.r),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Metric(value: area, label: 'Total Area', align: TextAlign.center),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  value: distance,
                  label: 'Total Distance',
                  align: TextAlign.left,
                ),
              ),
              Expanded(
                child: _Metric(
                  value: duration,
                  label: 'Duration',
                  align: TextAlign.center,
                ),
              ),
              Expanded(
                child: _Metric(
                  value: pace,
                  label: 'Average Pace',
                  align: TextAlign.right,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.value,
    required this.label,
    required this.align,
  });

  final String value;
  final String label;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: _crossAxisAlignment,
      children: [
        Text(
          value,
          textAlign: align,
          style: AppTextStyles.poppins(
            size: 18,
            color: AppColors.textPrimary,
            weight: FontWeight.w800,
            height: 1.1,
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          label,
          textAlign: align,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.montserrat(
            size: 14,
            color: AppColors.textSecondary,
            weight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  CrossAxisAlignment get _crossAxisAlignment {
    switch (align) {
      case TextAlign.left:
        return CrossAxisAlignment.start;
      case TextAlign.right:
        return CrossAxisAlignment.end;
      default:
        return CrossAxisAlignment.center;
    }
  }
}

class _PauseRunButton extends StatelessWidget {
  const _PauseRunButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: AppColors.blueColor, width: 1.5),
        ),
        child: Text(
          'Pause Run',
          style: AppTextStyles.montserrat(
            size: 16,
            color: AppColors.blueColor,
            weight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _PausedRunActions extends StatelessWidget {
  const _PausedRunActions({required this.onResume, required this.onFinish});

  final VoidCallback onResume;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _RunActionButton(
            label: 'Resume Run',
            onTap: onResume,
            isFilled: false,
          ),
        ),
        SizedBox(width: 14.w),
        Expanded(
          child: _RunActionButton(
            label: 'Finish Run',
            onTap: onFinish,
            isFilled: true,
          ),
        ),
      ],
    );
  }
}

class _RunActionButton extends StatelessWidget {
  const _RunActionButton({
    required this.label,
    required this.onTap,
    required this.isFilled,
  });

  final String label;
  final VoidCallback onTap;
  final bool isFilled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isFilled ? AppColors.blueColor : Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: AppColors.blueColor, width: 1.5),
        ),
        child: Text(
          label,
          style: AppTextStyles.montserrat(
            size: 15,
            color: isFilled ? Colors.white : AppColors.blueColor,
            weight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
