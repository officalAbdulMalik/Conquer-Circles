import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/models/badge_model.dart';
import 'package:test_steps/widgets/shared/app_borders.dart';
import 'package:test_steps/widgets/shared/app_text_input.dart';

class BadgesTabSection extends StatelessWidget {
  const BadgesTabSection({
    super.key,
    this.badges = const [],
    this.onSearchTap,
    this.onFilterTap,
    this.onBadgeTap,
  });

  final List<BadgeModel> badges;
  final VoidCallback? onSearchTap;
  final VoidCallback? onFilterTap;
  final ValueChanged<BadgeCardData>? onBadgeTap;

  @override
  Widget build(BuildContext context) {
    final visibleBadges = badges.isEmpty
        ? const [
            BadgeCardData(
              title: 'Step Rookie',
              subtitle: 'Walk 5,000 steps a day',
              unlocked: false,
              category: BadgeCategory.steps,
            ),
            BadgeCardData(
              title: 'Daily Grinder',
              subtitle: '10,000 steps in 5 days',
              unlocked: false,
              category: BadgeCategory.steps,
            ),
            BadgeCardData(
              title: 'Marathon Walker',
              subtitle: 'Walk 42km total season',
              unlocked: false,
              category: BadgeCategory.steps,
            ),
          ]
        : badges
              .map(
                (badge) => BadgeCardData(
                  title: badge.title,
                  subtitle: badge.description,
                  unlocked: badge.isUnlocked,
                  icon: badge.icon,
                  category: badge.category,
                ),
              )
              .toList();

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
                padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 12.h),
                width: 50.w,
                height: 50.w,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: AppBorders.raised(),
                ),
                child: Image.asset(
                  'assets/icons/filter.png',
                  height: 15.sp,
                  width: 15.sp,
                ),
              ),
            ),
          ],
        ),
        14.verticalSpace,
        GridView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: visibleBadges.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12.w,
            mainAxisSpacing: 12.h,
            childAspectRatio: 1.05,
          ),
          itemBuilder: (context, index) {
            final badge = visibleBadges[index];

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
            BadgeIcon(unlocked: badge.unlocked, icon: badge.icon),
            8.verticalSpace,
            Text(
              badge.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.montserrat(
                size: 14.sp,
                color: titleColor,
                weight: FontWeight.w600,
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BadgeIcon extends StatelessWidget {
  const BadgeIcon({super.key, required this.unlocked, this.icon});

  final bool unlocked;

  /// Badge icon from Supabase. Either an image URL or an emoji placeholder.
  final String? icon;

  bool get _hasImage => icon != null && icon!.startsWith('http');

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
          child: Center(child: _hasImage ? _buildImage() : _buildFallback()),
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

  /// Badge image from Supabase storage; greyed out when locked.
  Widget _buildImage() {
    final image = ClipRRect(
      borderRadius: BorderRadius.circular(12.r),
      child: Image.network(
        icon!,
        width: 40.w,
        height: 40.w,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return SizedBox(
            width: 40.w,
            height: 40.w,
            child: Center(
              child: SizedBox(
                width: 16.w,
                height: 16.w,
                child: const CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => _buildFallback(),
      ),
    );

    if (unlocked) return image;

    // Locked: render the badge art in grayscale at reduced opacity.
    return Opacity(
      opacity: 0.45,
      child: ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.2126, 0.7152, 0.0722, 0, 0, //
          0.2126, 0.7152, 0.0722, 0, 0, //
          0.2126, 0.7152, 0.0722, 0, 0, //
          0, 0, 0, 1, 0, //
        ]),
        child: image,
      ),
    );
  }

  Widget _buildFallback() {
    return Container(
      width: 34.w,
      height: 34.w,
      decoration: BoxDecoration(
        color: unlocked ? const Color(0xFFFFCC00) : AppColors.divider,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.emoji_events_rounded,
        size: 21.sp,
        color: unlocked ? AppColors.textPrimary : const Color(0xFF9CA3AF),
      ),
    );
  }
}

class BadgeCardData {
  const BadgeCardData({
    required this.title,
    required this.subtitle,
    required this.unlocked,
    this.icon,
    this.category,
  });

  final String title;
  final String subtitle;
  final bool unlocked;

  /// Image URL (or emoji placeholder) for the badge icon.
  final String? icon;

  /// Badge category from the Supabase `badges` table (steps, territory, ...).
  final BadgeCategory? category;

  bool get isStepsBadge => category == BadgeCategory.steps;
}
