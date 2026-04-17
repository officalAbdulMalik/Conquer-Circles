import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/features/social/mock_data/raid_alerts_mock_data.dart';
import 'package:test_steps/features/social/models/raid_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Status helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Extension on [RaidStatus] to provide UI-related properties.
extension RaidStatusX on RaidStatus {
  /// The display label for this status.
  String get label {
    switch (this) {
      case RaidStatus.activeAttack:
        return 'Active Attack';
      case RaidStatus.repelled:
        return 'Repelled';
      case RaidStatus.zoneLost:
        return 'Zone Lost';
    }
  }

  /// The color of the status dot.
  Color get dotColor {
    switch (this) {
      case RaidStatus.activeAttack:
        return AppColors.error;
      case RaidStatus.repelled:
        return AppColors.success;
      case RaidStatus.zoneLost:
        return AppColors.textSecondary;
    }
  }

  /// The background color for the row based on status.
  Color get rowBg {
    switch (this) {
      case RaidStatus.activeAttack:
        return AppColors.error.withValues(alpha: 0.05);
      case RaidStatus.repelled:
        return AppColors.success.withValues(alpha: 0.05);
      case RaidStatus.zoneLost:
        return Colors.transparent;
    }
  }

  bool get showDefend => this == RaidStatus.activeAttack;
}

// ─────────────────────────────────────────────────────────────────────────────
// Main widget
// ─────────────────────────────────────────────────────────────────────────────

/// A card widget that displays a list of raid alerts with their statuses.
///
/// This widget shows raid alerts in a scrollable list format, allowing users
/// to view active attacks, repelled raids, and lost zones. It includes
/// interactive elements for defending against active attacks.
///
/// Example usage:
/// ```dart
/// RaidAlertsCard(
///   alerts: myAlerts,
///   activeCount: 2,
///   onSeeAll: () => navigateToAllAlerts(),
///   onDefend: (alert) => defendRaid(alert),
/// )
/// ```
class RaidAlertsCard extends StatelessWidget {
  /// Creates a [RaidAlertsCard].
  ///
  /// [alerts] - List of raid alerts to display. Defaults to sample data.
  /// [activeCount] - Number of active alerts, shown in the badge.
  /// [onSeeAll] - Callback when "See all" is tapped.
  /// [onDefend] - Callback when "Defend!" button is pressed for an active attack.
  const RaidAlertsCard({
    super.key,
    this.alerts,
    this.activeCount = 0,
    this.onSeeAll,
    this.onDefend,
  });

  final List<RaidAlert>? alerts;
  final int activeCount;
  final VoidCallback? onSeeAll;
  final void Function(RaidAlert)? onDefend;

  @override
  Widget build(BuildContext context) {
    final list = alerts ?? sampleRaidAlerts;
    final computedActiveCount = list
        .where((alert) => alert.status == RaidStatus.activeAttack)
        .length;
    final badgeCount = activeCount > 0 ? activeCount : computedActiveCount;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 20.r,
            offset: Offset(0, 6.h),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ─────────────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 10.h),
            child: Row(
              children: [
                const Icon(
                  Icons.notifications_outlined,
                  color: AppColors.error,
                  size: 20,
                ),
                6.horizontalSpace,
                Text('Raid Alerts', style: AppTextStyles.heading3),
                7.horizontalSpace,
                // Badge
                if (badgeCount > 0)
                  Container(
                    width: 20.r,
                    height: 20.r,
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$badgeCount',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                const Spacer(),
                GestureDetector(
                  onTap: onSeeAll,
                  child: Text(
                    'See all',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.accentPurple,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Divider ────────────────────────────────────────────────────────
          const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F6)),

          // ── Alert rows ─────────────────────────────────────────────────────
          if (list.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    color: AppColors.success,
                    size: 18,
                  ),
                  8.horizontalSpace,
                  Expanded(
                    child: Text(
                      'No active raid alerts in your circle right now.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ...list.asMap().entries.map((entry) {
              final isLast = entry.key == list.length - 1;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _AlertRow(
                    alert: entry.value,
                    onDefend: onDefend != null
                        ? () => onDefend!(entry.value)
                        : null,
                  ),
                  if (!isLast)
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFF0F0F6),
                    ),
                ],
              );
            }),

          SizedBox(height: 4.h),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Single alert row
// ─────────────────────────────────────────────────────────────────────────────

/// A private widget representing a single raid alert row.
///
/// Displays the alert details including attacker, target, status, and time.
/// Includes a defend button for active attacks.
class _AlertRow extends StatelessWidget {
  /// Creates an [_AlertRow].
  const _AlertRow({required this.alert, this.onDefend});

  /// The raid alert to display.
  final RaidAlert alert;

  /// Callback when the defend button is pressed.
  final VoidCallback? onDefend;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      color: alert.status.rowBg,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      child: Row(
        children: [
          // Icon circle
          Container(
            width: 38.r,
            height: 38.r,
            decoration: BoxDecoration(
              color: alert.status.dotColor.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(alert.iconEmoji, style: TextStyle(fontSize: 17.sp)),
            ),
          ),

          SizedBox(width: 11.w),

          // Text block
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Route line  →
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: alert.attacker,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(
                        text: ' → ',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      TextSpan(
                        text: alert.target,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textNavy,
                        ),
                      ),
                    ],
                  ),
                ),

                3.verticalSpace,

                // Status + time
                Row(
                  children: [
                    Container(
                      width: 7.r,
                      height: 7.r,
                      decoration: BoxDecoration(
                        color: alert.status.dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 5.w),
                    Text(
                      alert.status.label,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: alert.status.dotColor,
                      ),
                    ),
                    SizedBox(width: 5.w),
                    Text(
                      '· ${alert.timeAgo}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Defend button (active attacks only)
          // if (alert.status.showDefend) ...[],
        ],
      ),
    );
  }
}
