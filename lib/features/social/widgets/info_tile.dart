import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';

// ─────────────────────────────────────────────
// CORE TILE WIDGET
// A flexible, reusable tile used across the app
// ─────────────────────────────────────────────

enum TileVariant {
  stat, // Icon + big number + label (e.g., 14/20 Members)
  requirement, // Check icon + label + status badge
  leaderboard, // Rank + avatar + name + XP
  chatMessage, // Avatar + username + time + message
}

class InfoTile extends StatelessWidget {
  final TileVariant variant;

  // Shared
  final String? label;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  // stat variant
  final IconData? icon;
  final Color? iconColor;
  final String? value;
  final String? subValue; // e.g. "/20" in "14/20"

  // requirement variant
  final bool? isMet;
  final String? statusText;

  // leaderboard variant
  final int? rank;
  final Widget? leadingWidget; // avatar/icon widget
  final String? trailingValue;
  final Color? trailingColor;
  final bool? isCurrentUser;

  // chat variant
  final String? username;
  final String? timeAgo;
  final String? message;
  final Color? avatarColor;

  const InfoTile({
    super.key,
    required this.variant,
    this.label,
    this.padding,
    this.backgroundColor,
    this.onTap,
    // stat
    this.icon,
    this.iconColor,
    this.value,
    this.subValue,
    // requirement
    this.isMet,
    this.statusText,
    // leaderboard
    this.rank,
    this.leadingWidget,
    this.trailingValue,
    this.trailingColor,
    this.isCurrentUser,
    // chat
    this.username,
    this.timeAgo,
    this.message,
    this.avatarColor,
  });

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case TileVariant.stat:
        return _StatTile(
          icon: icon!,
          iconColor: iconColor ?? AppColors.primary,
          value: value!,
          subValue: subValue,
          label: label!,
          backgroundColor: backgroundColor,
          padding: padding,
          onTap: onTap,
        );
      case TileVariant.requirement:
        return _RequirementTile(
          label: label!,
          isMet: isMet ?? false,
          statusText: statusText ?? (isMet == true ? 'Met' : 'Not Met'),
          padding: padding,
          onTap: onTap,
        );
      case TileVariant.leaderboard:
        return _LeaderboardTile(
          rank: rank!,
          leadingWidget: leadingWidget,
          name: label!,
          xp: trailingValue!,
          xpColor: trailingColor ?? AppColors.primary,
          isCurrentUser: isCurrentUser ?? false,
          padding: padding,
          onTap: onTap,
        );
      case TileVariant.chatMessage:
        return _ChatTile(
          username: username!,
          timeAgo: timeAgo ?? '',
          message: message!,
          avatarColor: avatarColor ?? AppColors.primary,
          padding: padding,
          onTap: onTap,
        );
    }
  }
}

// ─────────────────────────────────────────────
// STAT TILE
// ─────────────────────────────────────────────
class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String? subValue;
  final String label;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const _StatTile({
    required this.icon,
    required this.iconColor,
    required this.value,
    this.subValue,
    required this.label,
    this.backgroundColor,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            padding ?? const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: backgroundColor ?? AppColors.primaryLighter,
          borderRadius: BorderRadius.circular(10.sp),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 20),
            6.verticalSpace,
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: AppTextStyles.heading3.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                if (subValue != null)
                  Text(
                    subValue!,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
            2.verticalSpace,
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(fontSize: 10.sp),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// REQUIREMENT TILE
// ─────────────────────────────────────────────
class _RequirementTile extends StatelessWidget {
  final String label;
  final bool isMet;
  final String statusText;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const _RequirementTile({
    required this.label,
    required this.isMet,
    required this.statusText,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: padding ?? const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isMet
                    ? AppColors.green.withValues(alpha: 0.12)
                    : AppColors.textMuted.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isMet ? Icons.check_circle_rounded : Icons.cancel_rounded,
                size: 16,
                color: isMet ? AppColors.green : AppColors.textMuted,
              ),
            ),
            10.horizontalSpace,
            Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
            Text(
              '✓ $statusText',
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isMet ? AppColors.green : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// LEADERBOARD TILE
// ─────────────────────────────────────────────
class _LeaderboardTile extends StatelessWidget {
  final int rank;
  final Widget? leadingWidget;
  final String name;
  final String xp;
  final Color xpColor;
  final bool isCurrentUser;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const _LeaderboardTile({
    required this.rank,
    this.leadingWidget,
    required this.name,
    required this.xp,
    required this.xpColor,
    this.isCurrentUser = false,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            padding ?? const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.divider, width: 1),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: Text(
                '#$rank',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            10.horizontalSpace,
            if (leadingWidget != null) ...[leadingWidget!, 10.horizontalSpace],
            Expanded(
              child: Text(
                name,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 14,
                  fontWeight: isCurrentUser ? FontWeight.w700 : FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Text(
              xp,
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: xpColor,
              ),
            ),
            if (isCurrentUser) ...[
              6.horizontalSpace,
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// CHAT MESSAGE TILE
// ─────────────────────────────────────────────
class _ChatTile extends StatelessWidget {
  final String username;
  final String timeAgo;
  final String message;
  final Color avatarColor;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const _ChatTile({
    required this.username,
    required this.timeAgo,
    required this.message,
    required this.avatarColor,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: padding ?? const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: avatarColor.withValues(alpha: 0.15),
              child: Icon(Icons.person_rounded, size: 16, color: avatarColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        username,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      6.horizontalSpace,
                      Text(timeAgo, style: AppTextStyles.caption),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(message, style: AppTextStyles.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
