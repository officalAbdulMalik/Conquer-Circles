import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';

class RunSessionSummaryPanel extends StatefulWidget {
  const RunSessionSummaryPanel({
    super.key,
    required this.startedAt,
    required this.pausedAt,
    required this.distanceKm,
    required this.steps,
    required this.claimedAreaKm2,
    required this.isPaused,
    required this.onPause,
    required this.onResume,
    required this.onFinish,
    required this.onHistory,
  });

  final DateTime startedAt;
  final DateTime? pausedAt;
  final double distanceKm;
  final int steps;
  final double claimedAreaKm2;
  final bool isPaused;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onFinish;
  final VoidCallback onHistory;

  @override
  State<RunSessionSummaryPanel> createState() => _RunSessionSummaryPanelState();
}

class _RunSessionSummaryPanelState extends State<RunSessionSummaryPanel> {
  Timer? _ticker;

  /// Clock tick — ValueNotifier so each second rebuilds only the two
  /// time-derived metrics, not the whole panel.
  final ValueNotifier<DateTime> _now = ValueNotifier(DateTime.now());

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !widget.isPaused) {
        _now.value = DateTime.now();
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _now.dispose();
    super.dispose();
  }

  Duration _elapsedAt(DateTime now) {
    final end = widget.isPaused ? widget.pausedAt ?? now : now;
    return end.difference(widget.startedAt);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: widget.isPaused ? 0.36 : 0.34,
      minChildSize: widget.isPaused ? 0.34 : 0.32,
      maxChildSize: 0.42,
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
            child: ListView(
              controller: scrollController,
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 14.h),
              children: [
                Center(
                  child: Container(
                    width: 49,
                    height: 5,
                    margin: EdgeInsets.only(bottom: 14.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9DCE4),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 16.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCEBFF),
                    borderRadius: BorderRadius.circular(24.r),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _Metric(
                              value: _formatArea(widget.claimedAreaKm2),
                              label: 'Claimed Area',
                            ),
                          ),
                          Expanded(
                            child: _Metric(
                              value: '${widget.steps}',
                              label: 'Steps',
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      Row(
                        children: [
                          Expanded(
                            child: _Metric(
                              value: _formatDistance(widget.distanceKm),
                              label: 'Total Distance',
                            ),
                          ),
                          Expanded(
                            child: ValueListenableBuilder<DateTime>(
                              valueListenable: _now,
                              builder: (context, now, _) => _Metric(
                                value: _formatDuration(_elapsedAt(now)),
                                label: 'Duration',
                              ),
                            ),
                          ),
                          Expanded(
                            child: ValueListenableBuilder<DateTime>(
                              valueListenable: _now,
                              builder: (context, now, _) => _Metric(
                                value: _formatPace(
                                  _elapsedAt(now),
                                  widget.distanceKm,
                                  widget.steps,
                                ),
                                label: 'Average Pace',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.h),
                TextButton(
                  onPressed: widget.onHistory,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size(40.w, 40.h),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Icon(Icons.history_rounded),
                ),
                if (widget.isPaused)
                  Row(
                    children: [
                      Expanded(
                        child: _RunButton(
                          label: 'Resume Run',
                          onTap: widget.onResume,
                        ),
                      ),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: _RunButton(
                          label: 'Finish Run',
                          onTap: widget.onFinish,
                          filled: true,
                        ),
                      ),
                    ],
                  )
                else
                  _RunButton(label: 'Pause Run', onTap: widget.onPause),
              ],
            ),
          ),
        );
      },
    );
  }

  static String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (duration.inHours > 0) {
      return '${duration.inHours}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  static String _formatDistance(double distanceKm) {
    return '${distanceKm.toStringAsFixed(distanceKm < 10 ? 2 : 1)}km';
  }

  static String _formatArea(double areaKm2) {
    return '${areaKm2.toStringAsFixed(areaKm2 < 1 ? 3 : 2)}km²';
  }

  static String _formatPace(Duration elapsed, double distanceKm, int steps) {
    if (distanceKm < 0.02 || steps < 10 || elapsed.inSeconds <= 0) {
      return '--/km';
    }
    final secondsPerKm = elapsed.inSeconds / distanceKm;
    final minutes = secondsPerKm ~/ 60;
    final seconds = (secondsPerKm % 60).round().toString().padLeft(2, '0');
    return '$minutes:$seconds/km';
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          style: AppTextStyles.poppins(
            size: 18,
            color: AppColors.textPrimary,
            weight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.montserrat(
            size: 13,
            color: AppColors.textSecondary,
            weight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _RunButton extends StatelessWidget {
  const _RunButton({
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? AppColors.blueColor : Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: AppColors.blueColor, width: 1.5),
        ),
        child: Text(
          label,
          style: AppTextStyles.montserrat(
            size: 15,
            color: filled ? Colors.white : AppColors.blueColor,
            weight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
