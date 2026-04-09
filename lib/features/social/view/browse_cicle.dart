import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/features/social/mock_data/circles_mock_data.dart';
import 'package:test_steps/features/social/models/circle_models.dart';
import 'package:test_steps/features/social/view/circle_details.dart';
import 'package:test_steps/widgets/search_text_field.dart';
import 'package:test_steps/widgets/shared/app_avatar_stack.dart';
import 'package:test_steps/widgets/shared/app_button.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────

/// A page that displays a list of all available circles for browsing and joining.
///
/// This page shows circles in a scrollable list with detailed information
/// including stats, tags, and join options.
class AllCirclesPage extends StatelessWidget {
  /// Creates an [AllCirclesPage].
  const AllCirclesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: // ── Sticky header ─────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Browse Circles',
                  style: AppTextStyles.poppins(
                    size: 20,
                    color: AppColors.textNavy,
                    weight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  '8 circles · Find your squad',
                  style: AppTextStyles.poppins(
                    size: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            Container(
              padding: EdgeInsets.all(12.sp),
              decoration: BoxDecoration(
                color: AppColors.fillColor,
                shape: BoxShape.circle,
              ),
              child: SvgPicture.asset(
                'assets/icons/filter.svg',
                width: 16.w,
                height: 16.h,
                colorFilter: const ColorFilter.mode(
                  AppColors.brandPurple,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          child: ListView(
            children: [
              CustomTextFormField(
                hintText: 'Search circles, tags, regions...',
                onChanged: (value) {
                  // Handle search filtering
                },
              ),

              10.verticalSpace,

                Text(
                  'Featured Circles',
                  style: AppTextStyles.sectionTitle.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 16.sp,
                ),
              ),

              10.verticalSpace,

              _CircleCard(data: sampleCircles[1]),

              10.verticalSpace,

              Text(
                'All Circles',
                style: AppTextStyles.sectionTitle.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 16.sp,
                ),
              ),
              10.verticalSpace,

              // ── Cards ─────────────────────────────────────────────────────
              Column(
                children: List.generate(
                  sampleCircles.length,
                  (i) => Padding(
                    padding: EdgeInsets.only(bottom: 14.h),
                    child: _CircleCard(data: sampleCircles[i]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Circle card
// ─────────────────────────────────────────────────────────────────────────────

/// A card widget displaying detailed information about a circle.
class _CircleCard extends StatelessWidget {
  /// Creates a [_CircleCard].
  const _CircleCard({required this.data});

  final CircleData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: data.cardBgColor,
        borderRadius: BorderRadius.circular(22.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Row 1: logo + name + rank ──────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LogoBox(emoji: data.logoEmoji, bg: data.logoBgColor),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          data.name,
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 14.sp,
                          ),
                        ),
                        if (data.badge != null) ...[
                          SizedBox(width: 8.w),
                          _Badge(label: data.badge!, color: data.badgeColor!),
                        ],
                      ],
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      data.quote,
                      style: AppTextStyles.poppins(
                        size: 12.5,
                        color: AppColors.textSecondary,
                      ).copyWith(fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              _RankChip(rank: data.rank, trend: data.rankTrend),
            ],
          ),

          SizedBox(height: 12.h),

          // ── Row 2: stats ──────────────────────────────────────────────
          _StatsRow(data: data),

          SizedBox(height: 10.h),

          // ── Row 3: tags + members + action ────────────────────────────
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6.w,
                  runSpacing: 6.h,
                  children: data.tags.map((t) => _TagChip(tag: t)).toList(),
                ),
              ),
            ],
          ),

          SizedBox(height: 10.h),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _MemberAvatars(emojis: data.memberEmojis),
              _ActionButton(status: data.joinStatus, color: data.joinColor),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Logo box
// ─────────────────────────────────────────────────────────────────────────────

/// A widget displaying the circle's logo emoji in a colored box.
class _LogoBox extends StatelessWidget {
  /// Creates a [_LogoBox].
  const _LogoBox({required this.emoji, required this.bg});

  final String emoji;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52.r,
      height: 52.r,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Center(
        child: Text(emoji, style: TextStyle(fontSize: 26.sp)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Badge (Hot / New)
// ─────────────────────────────────────────────────────────────────────────────

/// A badge widget for displaying special labels like "Hot" or "New".
class _Badge extends StatelessWidget {
  /// Creates a [_Badge].
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        label,
        style: AppTextStyles.poppins(
          size: 11,
          color: color,
          weight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Rank chip
// ─────────────────────────────────────────────────────────────────────────────

/// A widget displaying the circle's rank with trend indicator.
class _RankChip extends StatelessWidget {
  /// Creates a [_RankChip].
  const _RankChip({required this.rank, required this.trend});

  final int rank;
  final int trend;

  Color get _trendColor => trend > 0
      ? AppColors.success
      : trend < 0
      ? AppColors.error
      : AppColors.textSecondary;

  String get _trendIcon => trend > 0
      ? '▲'
      : trend < 0
      ? '▼'
      : '';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.star_border_rounded,
              size: 13,
              color: AppColors.textSecondary,
            ),
            SizedBox(width: 2.w),
            Text(
              '#$rank',
              style: AppTextStyles.poppins(
                size: 13,
                color: AppColors.textSecondary,
                weight: FontWeight.w700,
              ),
            ),
          ],
        ),
        if (_trendIcon.isNotEmpty)
          Text(
            _trendIcon,
            style: AppTextStyles.inter(
              size: 11,
              color: _trendColor,
              weight: FontWeight.w700,
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats row
// ─────────────────────────────────────────────────────────────────────────────

/// A row displaying the circle's key statistics.
class _StatsRow extends StatelessWidget {
  /// Creates a [_StatsRow].
  const _StatsRow({required this.data});

  final CircleData data;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _StatItem(
            icon: '👥',
            value: '${data.members}/${data.maxMembers}',
            label: 'members',
          ),
          SizedBox(width: 14.w),
          _StatItem(icon: '📍', value: '${data.zones}', label: 'zones'),
          SizedBox(width: 14.w),
          _StatItem(icon: '🏆', value: '${data.wins}', label: 'wins'),
          SizedBox(width: 14.w),
          _StatItem(icon: '⚡', value: data.xp, label: 'XP'),
        ],
      ),
    );
  }
}

/// A single statistic item.
class _StatItem extends StatelessWidget {
  /// Creates a [_StatItem].
  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  final String icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: TextStyle(fontSize: 12.sp)),
        SizedBox(width: 3.w),
        Text(
          '$value ',
          style: AppTextStyles.poppins(
            size: 12,
            color: AppColors.textNavy,
            weight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.poppins(
            size: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tag chip
// ─────────────────────────────────────────────────────────────────────────────

/// A chip widget for displaying circle tags.
class _TagChip extends StatelessWidget {
  /// Creates a [_TagChip].
  const _TagChip({required this.tag});

  final CircleTag tag;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: tag.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: tag.color.withValues(alpha: 0.25),
          width: 1.w,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (tag.icon != null) ...[
            Text(tag.icon!, style: TextStyle(fontSize: 11.sp)),
            SizedBox(width: 3.w),
          ],
          Text(
            tag.label,
            style: AppTextStyles.poppins(
              size: 11.5,
              color: tag.color,
              weight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Member avatars stack
// ─────────────────────────────────────────────────────────────────────────────

/// A stacked widget displaying member avatars.
class _MemberAvatars extends StatelessWidget {
  /// Creates [_MemberAvatars].
  const _MemberAvatars({required this.emojis});

  final List<String> emojis;

  @override
  Widget build(BuildContext context) {
    return AppAvatarStack(
      emojis: emojis,
      size: 30,
      overlap: 18,
      backgroundColor: AppColors.surface,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action button
// ─────────────────────────────────────────────────────────────────────────────

/// A button for joining or requesting to join a circle.
class _ActionButton extends StatelessWidget {
  /// Creates an [_ActionButton].
  const _ActionButton({required this.status, required this.color});

  final JoinStatus status;
  final Color color;

  String get _label {
    switch (status) {
      case JoinStatus.join:
        return 'View Circle';
      case JoinStatus.request:
        return 'Request';
      case JoinStatus.full:
        return 'Full';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFull = status == JoinStatus.full;
    final isJoin = status == JoinStatus.join;
    return AppButton(
      label: _label,
      icon: isJoin ? Icons.arrow_forward_ios : null,
      variant: isFull ? AppButtonVariant.outlined : AppButtonVariant.filled,
      backgroundColor: isJoin ? AppColors.brandPurple : color,
      foregroundColor: AppColors.surface,
      borderColor: AppColors.textSecondary.withValues(alpha: 0.25),
      height: 34,
      borderRadius: 18,
      horizontalPadding: 12,
      textStyle: AppTextStyles.poppins(
        size: 14,
        color: isFull ? AppColors.textSecondary : AppColors.surface,
        weight: FontWeight.w600,
      ),
      onPressed: isFull
          ? null
          : () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => CircleProfileScreen()));
            },
    );
  }
}
