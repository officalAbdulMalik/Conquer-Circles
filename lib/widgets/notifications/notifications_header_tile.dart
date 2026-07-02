import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/widgets/notifications/notification_filter_mode.dart';
import 'package:test_steps/widgets/shared/app_borders.dart';

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
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HeaderIconButtonTile(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => Navigator.maybePop(context),
              ),
              12.horizontalSpace,
              Expanded(
                child: NotificationsTitleTile(
                  unreadCount: unreadCount,
                  totalCount: totalCount,
                ),
              ),
              if (unreadCount > 0) ...[
                ReadAllActionTile(onTap: onMarkAllRead),
                8.horizontalSpace,
              ],
              HeaderIconButtonTile(
                icon: Icons.tune_rounded,
                onTap: onOptionsTap,
              ),
            ],
          ),
          16.verticalSpace,
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
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
        Text(
          'Notifications',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.montserrat(
            size: 18,
            color: const Color(0xFF111827),
            weight: FontWeight.w700,
          ),
        ),
        4.verticalSpace,
        Text(
          '$unreadCount unread · $totalCount total',
          style: AppTextStyles.montserrat(
            size: 12,
            color: AppColors.textSecondary,
            weight: FontWeight.w500,
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
      color: AppColors.blueColor,
      borderRadius: BorderRadius.circular(24.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(24.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.done_all_rounded,
                color: AppColors.surface,
                size: 14.sp,
              ),
              5.horizontalSpace,
              Text(
                'Read all',
                style: AppTextStyles.montserrat(
                  size: 11,
                  color: AppColors.surface,
                  weight: FontWeight.w700,
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
      width: 42.w,
      height: 42.w,
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.borderColor),
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
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 42.w,
          height: 42.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.borderColor),
          ),
          child: Icon(icon, color: const Color(0xFF0F172A), size: 17.sp),
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
        style: AppTextStyles.montserrat(
          size: 10,
          color: AppColors.surface,
          weight: FontWeight.w700,
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
      color: isSelected ? AppColors.blueColor : AppColors.surface,
      borderRadius: BorderRadius.circular(24.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(24.r),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24.r),
            border: AppBorders.raised(),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                filter.icon,
                size: 14.sp,
                color: isSelected ? AppColors.surface : baseColor,
              ),
              6.horizontalSpace,
              Text(
                filter.label,
                style: AppTextStyles.montserrat(
                  size: 12,
                  color: isSelected
                      ? AppColors.surface
                      : const Color(0xFF111827),
                  weight: FontWeight.w500,
                ),
              ),
              if (count > 0) ...[
                8.horizontalSpace,
                HeaderBadgeTile(text: '$count', color: AppColors.error),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
