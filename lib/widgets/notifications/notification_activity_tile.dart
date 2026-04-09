import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/models/notification_model.dart';

class NotificationActivityTile extends StatelessWidget {
  const NotificationActivityTile({
    super.key,
    required this.notification,
    this.onTap,
    this.onActionTap,
    this.onLongPress,
  });

  final UserNotification notification;
  final VoidCallback? onTap;
  final VoidCallback? onActionTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final NotificationTileThemeData themeData =
        NotificationTileThemeResolver.resolve(notification.type);
    final Color tileColor = themeData.backgroundColor(notification.isRead);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: themeData.borderColor),
        boxShadow: themeData.shadowFor(notification.isRead),
      ),
      child: Material(
        color: AppColors.surface.withValues(alpha: 0),
        child: InkWell(
          borderRadius: BorderRadius.circular(18.r),
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NotificationIconTile(themeData: themeData),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      NotificationMetaRowTile(
                        title: notification.title,
                        tag: themeData.tag,
                        tagColor: themeData.accent,
                      ),
                      SizedBox(height: 5.h),
                      Text(
                        notification.message,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textNavy.withValues(alpha: 0.72),
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 10.h),
                      Row(
                        children: [
                          NotificationActionChipTile(
                            label: themeData.actionLabel,
                            color: themeData.actionColor,
                            icon: themeData.actionIcon,
                            onTap: onActionTap ?? onTap,
                          ),
                          const Spacer(),
                          Text(
                            DateFormat('h:mm a').format(notification.createdAt),
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!notification.isRead)
                  Padding(
                    padding: EdgeInsets.only(left: 6.w, top: 2.h),
                    child: Container(
                      width: 8.w,
                      height: 8.w,
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NotificationIconTile extends StatelessWidget {
  const NotificationIconTile({super.key, required this.themeData});

  final NotificationTileThemeData themeData;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38.w,
      height: 38.w,
      decoration: BoxDecoration(
        color: themeData.accent.withValues(alpha: 0.14),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(themeData.icon, color: themeData.accent, size: 19.sp),
    );
  }
}

class NotificationMetaRowTile extends StatelessWidget {
  const NotificationMetaRowTile({
    super.key,
    required this.title,
    required this.tag,
    required this.tagColor,
  });

  final String title;
  final String tag;
  final Color tagColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.cardTitle.copyWith(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(width: 8.w),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: tagColor.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(999.r),
          ),
          child: Text(
            tag,
            style: AppTextStyles.chipLabel.copyWith(
              color: tagColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class NotificationActionChipTile extends StatelessWidget {
  const NotificationActionChipTile({
    super.key,
    required this.label,
    required this.color,
    required this.icon,
    this.onTap,
  });

  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999.r),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(999.r),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.33),
              blurRadius: 10.r,
              offset: Offset(0, 3.h),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.surface, size: 12.sp),
            SizedBox(width: 4.w),
            Text(
              label,
              style: AppTextStyles.chipLabel.copyWith(
                color: AppColors.surface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NotificationTileThemeData {
  const NotificationTileThemeData({
    required this.icon,
    required this.accent,
    required this.actionColor,
    required this.actionLabel,
    required this.actionIcon,
    required this.tag,
    this.shadowTint,
  });

  final IconData icon;
  final Color accent;
  final Color actionColor;
  final String actionLabel;
  final IconData actionIcon;
  final String tag;
  final Color? shadowTint;

  Color backgroundColor(bool isRead) {
    final double alpha = isRead ? 0.08 : 0.16;
    return accent.withValues(alpha: alpha);
  }

  Color get borderColor => accent.withValues(alpha: 0.26);

  List<BoxShadow> shadowFor(bool isRead) {
    return <BoxShadow>[
      BoxShadow(
        color: AppColors.textNavy.withValues(alpha: 0.04),
        blurRadius: 12.r,
        offset: Offset(0, 5.h),
      ),
      if (!isRead)
        BoxShadow(
          color: (shadowTint ?? accent).withValues(alpha: 0.28),
          blurRadius: 20.r,
          spreadRadius: 0.6.r,
          offset: Offset(0, 8.h),
        ),
    ];
  }
}

class NotificationTileThemeResolver {
  static NotificationTileThemeData resolve(String type) {
    switch (type) {
      case 'territory_under_attack':
      case 'territory_lost':
      case 'raid_failed':
      case 'rival_dominating':
      case 'rival_nearby':
        return const NotificationTileThemeData(
          icon: Icons.gpp_bad_rounded,
          accent: AppColors.error,
          actionColor: AppColors.error,
          actionLabel: 'Defend',
          actionIcon: Icons.shield_outlined,
          tag: 'Alert',
          shadowTint: AppColors.error,
        );

      case 'streak_reminder':
      case 'daily_walk_reminder':
        return const NotificationTileThemeData(
          icon: Icons.local_fire_department_rounded,
          accent: AppColors.orange,
          actionColor: AppColors.orange,
          actionLabel: 'Keep Streak',
          actionIcon: Icons.directions_walk_rounded,
          tag: 'Streak',
          shadowTint: AppColors.warning,
        );

      case 'raid_victory':
      case 'territory_defended':
        return const NotificationTileThemeData(
          icon: Icons.flash_on_rounded,
          accent: AppColors.warning,
          actionColor: AppColors.warning,
          actionLabel: 'View Raid',
          actionIcon: Icons.bolt_rounded,
          tag: 'Raid',
          shadowTint: AppColors.warning,
        );

      case 'daily_summary':
      case 'cluster_created':
      case 'energy_full':
      case 'cluster_broken':
        return const NotificationTileThemeData(
          icon: Icons.timeline_rounded,
          accent: AppColors.info,
          actionColor: AppColors.info,
          actionLabel: 'See Stats',
          actionIcon: Icons.query_stats_rounded,
          tag: 'Progress',
          shadowTint: AppColors.info,
        );

      case 'badge_unlocked':
      case 'rare_badge':
      case 'season_results':
      case 'season_starting':
      case 'mid_season_reminder':
      case 'season_ending_soon':
        return const NotificationTileThemeData(
          icon: Icons.workspace_premium_rounded,
          accent: AppColors.brandPurple,
          actionColor: AppColors.brandPurple,
          actionLabel: 'Open Awards',
          actionIcon: Icons.emoji_events_rounded,
          tag: 'Awards',
          shadowTint: AppColors.brandPurple,
        );

      case 'circle_invite':
      case 'friend_joined_circle':
      case 'join_circle_reminder':
        return const NotificationTileThemeData(
          icon: Icons.groups_2_rounded,
          accent: AppColors.info,
          actionColor: AppColors.info,
          actionLabel: 'Open Circle',
          actionIcon: Icons.group_add_rounded,
          tag: 'Social',
          shadowTint: AppColors.info,
        );

      case 'first_territory':
      case 'welcome':
      case 'come_back':
        return const NotificationTileThemeData(
          icon: Icons.explore_rounded,
          accent: AppColors.success,
          actionColor: AppColors.success,
          actionLabel: 'Start Walk',
          actionIcon: Icons.map_rounded,
          tag: 'Quest',
          shadowTint: AppColors.success,
        );

      default:
        return const NotificationTileThemeData(
          icon: Icons.notifications_active_rounded,
          accent: AppColors.brandPrimary,
          actionColor: AppColors.brandPrimary,
          actionLabel: 'View',
          actionIcon: Icons.open_in_new_rounded,
          tag: 'General',
          shadowTint: AppColors.brandPrimary,
        );
    }
  }
}
