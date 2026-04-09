import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';

class NotificationsSummarySectionTile extends StatelessWidget {
  const NotificationsSummarySectionTile({
    super.key,
    required this.raidsCount,
    required this.awardsCount,
    required this.questsCount,
    required this.xpEventsCount,
    this.onRaidsTap,
    this.onAwardsTap,
    this.onQuestsTap,
    this.onXpEventsTap,
  });

  final int raidsCount;
  final int awardsCount;
  final int questsCount;
  final int xpEventsCount;
  final VoidCallback? onRaidsTap;
  final VoidCallback? onAwardsTap;
  final VoidCallback? onQuestsTap;
  final VoidCallback? onXpEventsTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Expanded(
            child: NotificationSummaryStatTile(
              icon: Icons.gpp_bad_rounded,
              iconColor: AppColors.error,
              count: raidsCount,
              label: 'Raids',
              onTap: onRaidsTap,
            ),
          ),
          Expanded(
            child: NotificationSummaryStatTile(
              icon: Icons.emoji_events_outlined,
              iconColor: AppColors.warning,
              count: awardsCount,
              label: 'Awards',
              onTap: onAwardsTap,
            ),
          ),
          Expanded(
            child: NotificationSummaryStatTile(
              icon: Icons.track_changes_rounded,
              iconColor: AppColors.brandPrimary,
              count: questsCount,
              label: 'Quests',
              onTap: onQuestsTap,
            ),
          ),
          Expanded(
            child: NotificationSummaryStatTile(
              icon: Icons.trending_up_rounded,
              iconColor: AppColors.accentPurple,
              count: xpEventsCount,
              label: 'XP Events',
              onTap: onXpEventsTap,
            ),
          ),
        ],
      ),
    );
  }
}

class NotificationSummaryStatTile extends StatelessWidget {
  const NotificationSummaryStatTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.count,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final int count;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface.withValues(alpha: 0),
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 4.h),
          child: Column(
            children: [
              Container(
                width: 36.w,
                height: 36.w,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: iconColor, size: 18.sp),
              ),
              SizedBox(height: 8.h),
              Text(
                '$count',
                style: AppTextStyles.cardTitle.copyWith(
                  fontSize: 14.sp,
                  color: AppColors.textNavy,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                label,
                style: AppTextStyles.chipLabel.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
