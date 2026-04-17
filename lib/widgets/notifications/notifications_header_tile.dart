import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/widgets/notifications/notification_filter_mode.dart';

class NotificationsHeaderTile extends StatelessWidget {
  const NotificationsHeaderTile({
    super.key,
    required this.unreadCount,
    required this.totalCount,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.filterCounts,
    this.onMarkAllRead,
    this.onOptionsTap,
  });

  final int unreadCount;
  final int totalCount;
  final NotificationFilterMode selectedFilter;
  final ValueChanged<NotificationFilterMode> onFilterChanged;
  final Map<NotificationFilterMode, int> filterCounts;
  final VoidCallback? onMarkAllRead;
  final VoidCallback? onOptionsTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HeaderIconButtonTile(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => Navigator.maybePop(context),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: NotificationsTitleTile(
                  unreadCount: unreadCount,
                  totalCount: totalCount,
                ),
              ),
              if (unreadCount > 0) ...[
                ReadAllActionTile(onTap: onMarkAllRead),
                SizedBox(width: 8.w),
              ],
              HeaderIconButtonTile(
                icon: Icons.tune_rounded,
                onTap: onOptionsTap,
              ),
            ],
          ),
          SizedBox(height: 14.h),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...NotificationFilterMode.values.map(
                  (NotificationFilterMode mode) => Padding(
                    padding: EdgeInsets.only(right: 8.w),
                    child: NotificationsFilterChipTile(
                      filter: mode,
                      count: filterCounts[mode] ?? 0,
                      isSelected: selectedFilter == mode,
                      onTap: () => onFilterChanged(mode),
                    ),
                  ),
                ),
                NotificationChipIconTile(icon: Icons.groups_2_outlined),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NotificationsTitleTile extends StatelessWidget {
  const NotificationsTitleTile({
    super.key,
    required this.unreadCount,
    required this.totalCount,
  });

  final int unreadCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [Text('Notifications', style: AppTextStyles.screenTitle)],
        ),
        SizedBox(height: 2.h),
        Text(
          '$unreadCount unread · $totalCount total',
          style: AppTextStyles.cardSubtitle.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class ReadAllActionTile extends StatelessWidget {
  const ReadAllActionTile({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.brandPurple.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(999.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(999.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 8.h),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.done_all_rounded,
                color: AppColors.brandPurple,
                size: 14.sp,
              ),
              SizedBox(width: 5.w),
              Text(
                'Read all',
                style: AppTextStyles.chipLabel.copyWith(
                  color: AppColors.brandPurple,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NotificationChipIconTile extends StatelessWidget {
  const NotificationChipIconTile({super.key, required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38.w,
      height: 34.h,
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(color: AppColors.borderLight),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: AppColors.textSecondary, size: 17.sp),
    );
  }
}

class HeaderIconButtonTile extends StatelessWidget {
  const HeaderIconButtonTile({
    super.key,
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: onTap,
        child: SizedBox(
          width: 34.w,
          height: 34.h,
          child: Icon(icon, color: AppColors.textNavy, size: 17.sp),
        ),
      ),
    );
  }
}

class HeaderBadgeTile extends StatelessWidget {
  const HeaderBadgeTile({super.key, required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Text(
        text,
        style: AppTextStyles.chipLabel.copyWith(
          color: AppColors.surface,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class NotificationsFilterChipTile extends StatelessWidget {
  const NotificationsFilterChipTile({
    super.key,
    required this.filter,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  final NotificationFilterMode filter;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color baseColor = filter.accentColor;

    return Material(
      color: isSelected
          ? baseColor.withValues(alpha: 0.18)
          : AppColors.surface.withValues(alpha: 0.78),
      borderRadius: BorderRadius.circular(999.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(999.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 8.h),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                filter.icon,
                size: 14.sp,
                color: isSelected ? baseColor : AppColors.textSecondary,
              ),
              SizedBox(width: 5.w),
              Text(
                filter.label,
                style: AppTextStyles.chipLabel.copyWith(
                  color: isSelected ? baseColor : AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (count > 0) ...[
                SizedBox(width: 6.w),
                HeaderBadgeTile(text: '$count', color: AppColors.error),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
