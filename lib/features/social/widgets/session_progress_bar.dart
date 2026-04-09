import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';

/// Displays a season XP progress bar with label and target.
class SeasonProgressBar extends StatelessWidget {
  final String seasonLabel;
  final int currentXP;
  final int targetXP;
  final Color? progressColor;

  const SeasonProgressBar({
    super.key,
    required this.seasonLabel,
    required this.currentXP,
    required this.targetXP,
    this.progressColor,
  });

  double get _progress => (currentXP / targetXP).clamp(0.0, 1.0);

  String _formatXP(int xp) {
    if (xp >= 1000) return '${(xp / 1000).toStringAsFixed(0)}k XP';
    return '$xp XP';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up_rounded, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(seasonLabel, style: AppTextStyles.heading3.copyWith(color: AppColors.primary)),
              const Spacer(),
              Text(
                _formatXP(currentXP),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 8,
              backgroundColor: AppColors.primaryLighter,
              valueColor: AlwaysStoppedAnimation<Color>(
                progressColor ?? AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text('Top 1 threshold', style: AppTextStyles.caption),
              const Spacer(),
              Text(_formatXP(targetXP), style: AppTextStyles.caption),
            ],
          ),
        ],
      ),
    );
  }
}