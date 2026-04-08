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
    this.activeCount = 1,
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
                const Icon(Icons.notifications_outlined, color: AppColors.error, size: 20),
                SizedBox(width: 6.w),
                Text(
                  'Raid Alerts',
                  style: AppTextStyles.poppins(
                    size: 16,
                    color: AppColors.textNavy,
                    weight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(width: 7.w),
                // Badge
                if (activeCount > 0)
                  Container(
                    width: 20.r,
                    height: 20.r,
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$activeCount',
                        style: AppTextStyles.poppins(
                          size: 11,
                          color: Colors.white,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                const Spacer(),
                GestureDetector(
                  onTap: onSeeAll,
                  child: Text(
                    'See all',
                    style: AppTextStyles.poppins(
                      size: 13,
                      color: AppColors.accentPurple,
                      weight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Divider ────────────────────────────────────────────────────────
          const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F6)),

          // ── Alert rows ─────────────────────────────────────────────────────
          ...list.asMap().entries.map((entry) {
            final isLast = entry.key == list.length - 1;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _AlertRow(
                  alert: entry.value,
                  onDefend: onDefend != null ? () => onDefend!(entry.value) : null,
                ),
                if (!isLast)
                  const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F6)),
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
              child: Text(
                alert.iconEmoji,
                style: TextStyle(fontSize: 17.sp),
              ),
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
                        style: AppTextStyles.poppins(
                          size: 14,
                          color: AppColors.textNavy,
                          weight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(
                        text: ' → ',
                        style: AppTextStyles.poppins(
                          size: 14,
                          color: AppColors.textSecondary,
                          weight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text: alert.target,
                        style: AppTextStyles.poppins(
                          size: 14,
                          color: AppColors.textNavy,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 3.h),

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
                      style: AppTextStyles.poppins(
                        size: 12,
                        color: alert.status.dotColor,
                        weight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 5.w),
                    Text(
                      '· ${alert.timeAgo}',
                      style: AppTextStyles.poppins(
                        size: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Defend button (active attacks only)
          if (alert.status.showDefend) ...[
            SizedBox(width: 10.w),
            ElevatedButton(
              onPressed: onDefend,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
                elevation: 0,
                textStyle: AppTextStyles.poppins(
                  size: 13,
                  color: Colors.white,
                  weight: FontWeight.w700,
                ),
              ),
              child: const Text('Defend!'),
            ),
          ],
        ],
      ),
    );
  }
}
