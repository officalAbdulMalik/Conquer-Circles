import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/constants/app_emojis.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/features/social/models/guild_models.dart';
import 'package:test_steps/features/social/widgets/guild/guild_logo.dart';
import 'package:test_steps/features/social/widgets/guild/member_avatar_row.dart';
import 'package:test_steps/features/social/widgets/guild/stat_tile.dart';

class GuildCard extends StatelessWidget {
  const GuildCard({
    super.key,
    this.circle,
    this.leaderboard,
    this.leagueName = 'Gold League',
    this.onAddTap,
  });

  final Map<String, dynamic>? circle;
  final List<dynamic>? leaderboard;
  final String leagueName;
  final VoidCallback? onAddTap;

  @override
  Widget build(BuildContext context) {
    final circleName = circle?['name']?.toString() ?? 'Unknown Circle';
    final maxMembers = (circle?['max_members'] as num?)?.toInt() ?? 25;
    final rawPrivate = circle?['is_private'];
    final isPrivate = rawPrivate is bool
        ? rawPrivate
        : (rawPrivate?.toString().toLowerCase() == 'true' ||
              rawPrivate?.toString() == '1');
    final circleRank = (circle?['rank'] as num?)?.toInt();

    String ownerName = 'Unknown';
    if (leaderboard != null) {
      for (final m in leaderboard!) {
        if (m['role'] == 'owner') {
          ownerName = m['username']?.toString() ?? 'Unknown';
          break;
        }
      }
    }

    final int membersCount = leaderboard?.length ?? 0;

    // Calculate total territories and raids
    int territories = 0;
    int raids = 0;
    if (leaderboard != null) {
      for (final m in leaderboard!) {
        territories += (m['territories'] as num?)?.toInt() ?? 0;
        raids += (m['raids_won'] as num?)?.toInt() ?? 0;
      }
    }

    final stats = [
      GuildStat(
        icon: Text(AppEmojis.members, style: TextStyle(fontSize: 18.sp)),
        value: '$membersCount/$maxMembers',
        label: 'Members',
      ),
      GuildStat(
        icon: Text(AppEmojis.map, style: TextStyle(fontSize: 18.sp)),
        value: '$territories',
        label: 'Territories',
      ),
      GuildStat(
        icon: Text(AppEmojis.swords, style: TextStyle(fontSize: 18.sp)),
        value: '$raids',
        label: 'Raids',
      ),
      GuildStat(
        icon: Text(AppEmojis.trophy, style: TextStyle(fontSize: 18.sp)),
        value: circleRank == null || circleRank <= 0 ? '#-' : '#$circleRank',
        label: 'Rank',
      ),
    ];

    final displayMembers =
        leaderboard?.take(6).map((m) {
          return GuildMember(
            avatarEmoji: AppEmojis.eagle, // default fallback
            bgColor: AppColors.avatarNeutral, // default fallback
            isOnline: true, // assume online for now
          );
        }).toList() ??
        [];

    final onlineCount = displayMembers.where((m) => m.isOnline).length;
    final extraMembers = (leaderboard != null && leaderboard!.length > 6)
        ? leaderboard!.length - 6
        : 0;

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(26.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 24.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Row ────────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const GuildLogo(),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(circleName, style: AppTextStyles.heading3),
                    3.verticalSpace,
                    Row(
                      children: [
                        Text(
                          AppEmojis.crown,
                          style: TextStyle(fontSize: 12.sp),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '$ownerName · $leagueName',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color:
                                (isPrivate
                                        ? AppColors.accentPurple
                                        : AppColors.success)
                                    .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Text(
                            isPrivate ? 'Private' : 'Public',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                              color: isPrivate
                                  ? AppColors.accentPurple
                                  : AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Add button
              // GestureDetector(
              //   onTap: onAddTap,
              //   child: Container(
              //     width: 36.r,
              //     height: 36.r,
              //     decoration: BoxDecoration(
              //       color: AppColors.tabActiveBg,
              //       shape: BoxShape.circle,
              //     ),
              //     child: Icon(
              //       Icons.add_rounded,
              //       color: AppColors.accentPurple,
              //       size: 20.r,
              //     ),
              //   ),
              // ),
            ],
          ),

          18.verticalSpace,

          // ── Stats row ─────────────────────────────────────────────────────
          Row(
            children: stats
                .map((s) => Expanded(child: StatTile(stat: s)))
                .toList(),
          ),

          SizedBox(height: 18.h),

          // ── Active members header ─────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Active Members', style: AppTextStyles.heading3),
              Row(
                children: [
                  Container(
                    width: 8.r,
                    height: 8.r,
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 5.w),
                  Text(
                    '$onlineCount online',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontSize: 14.sp,
                      color: AppColors.accentPurple,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),

          SizedBox(height: 12.h),

          // ── Member avatars row ───────────────────────────────────────────
          MemberAvatarRow(members: displayMembers, extraCount: extraMembers),
        ],
      ),
    );
  }
}
