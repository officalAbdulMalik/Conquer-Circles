import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/widgets/shared/app_borders.dart';
import 'package:test_steps/widgets/shared/app_text_input.dart';

class BadgesTabSection extends StatelessWidget {
  const BadgesTabSection({
    super.key,
    this.onSearchTap,
    this.onFilterTap,
    this.onBadgeTap,
  });

  final VoidCallback? onSearchTap;
  final VoidCallback? onFilterTap;
  final ValueChanged<BadgeCardData>? onBadgeTap;

  @override
  Widget build(BuildContext context) {
    const badges = [
      BadgeCardData(
        title: 'Step Rookie',
        subtitle: 'Walk 5,000 steps a day',
        unlocked: true,
      ),
      BadgeCardData(
        title: 'Step Rookie',
        subtitle: 'Walk 5,000 steps a day',
        unlocked: true,
      ),
      BadgeCardData(
        title: 'Daily Grinder',
        subtitle: '10,000 steps in 5 days',
        unlocked: true,
      ),
      BadgeCardData(
        title: 'Marathon Walker',
        subtitle: 'Walk 42km total season',
        unlocked: false,
      ),
      BadgeCardData(
        title: 'Trail Finder',
        subtitle: 'Capture 10 new tiles',
        unlocked: false,
      ),
      BadgeCardData(
        title: 'Energy Saver',
        subtitle: 'Finish a week with 50 energy',
        unlocked: false,
      ),
    ];

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: AppTextInput(
                hintText: 'Search badge...',
                readOnly: true,
                onTap: onSearchTap,
                prefixIcon: Icon(Icons.search_rounded, size: 18.sp),
              ),
            ),
            12.horizontalSpace,
            InkWell(
              customBorder: const CircleBorder(),
              onTap: onFilterTap,
              child: Container(
                width: 46.w,
                height: 46.w,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: AppBorders.raised(),
                ),
                child: Icon(
                  Icons.tune_rounded,
                  size: 20.sp,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        16.verticalSpace,
        GridView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: badges.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12.w,
            mainAxisSpacing: 12.h,
            childAspectRatio: 0.96,
          ),
          itemBuilder: (context, index) {
            final badge = badges[index];

            return BadgeGridCard(
              badge: badge,
              onTap: () => onBadgeTap?.call(badge),
            );
          },
        ),
      ],
    );
  }
}

class BadgeGridCard extends StatelessWidget {
  const BadgeGridCard({super.key, required this.badge, this.onTap});

  final BadgeCardData badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final titleColor = badge.unlocked
        ? AppColors.textPrimary
        : const Color(0xFFC7CDD8);
    final subtitleColor = badge.unlocked
        ? AppColors.textSecondary
        : const Color(0xFFD4D9E2);

    return InkWell(
      borderRadius: BorderRadius.circular(18.r),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.fromLTRB(12.w, 12.h, 10.w, 12.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18.r),
          border: AppBorders.raised(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BadgeIcon(unlocked: badge.unlocked),
            const Spacer(),
            Text(
              badge.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.montserrat(
                size: 15.sp,
                color: titleColor,
                weight: FontWeight.w700,
              ),
            ),
            8.verticalSpace,
            Text(
              badge.subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.montserrat(
                size: 12.sp,
                color: subtitleColor,
                weight: FontWeight.w400,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BadgeIcon extends StatelessWidget {
  const BadgeIcon({super.key, required this.unlocked});

  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 50.w,
          height: 50.w,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.borderColor, width: 1.w),
          ),
          child: Center(
            child: Container(
              width: 34.w,
              height: 34.w,
              decoration: BoxDecoration(
                color: unlocked ? const Color(0xFFFFCC00) : AppColors.divider,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.emoji_events_rounded,
                size: 21.sp,
                color: unlocked
                    ? AppColors.textPrimary
                    : const Color(0xFF9CA3AF),
              ),
            ),
          ),
        ),
        if (!unlocked)
          Positioned(
            right: -5.w,
            bottom: -3.h,
            child: Container(
              width: 22.w,
              height: 22.w,
              decoration: BoxDecoration(
                color: const Color(0xFFE7EBF1),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFB8C0CC), width: 1.w),
              ),
              child: Icon(
                Icons.lock_outline_rounded,
                size: 15.sp,
                color: const Color(0xFF9AA3B0),
              ),
            ),
          ),
      ],
    );
  }
}

class BadgeCardData {
  const BadgeCardData({
    required this.title,
    required this.subtitle,
    required this.unlocked,
  });

  final String title;
  final String subtitle;
  final bool unlocked;
}
