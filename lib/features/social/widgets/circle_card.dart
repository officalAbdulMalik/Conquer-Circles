import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/constants/app_emojis.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/features/social/models/guild_models.dart';
import 'package:test_steps/features/social/widgets/guild/guild_logo.dart';
import 'package:test_steps/features/social/widgets/guild/member_avatar_row.dart';
import 'package:test_steps/features/social/widgets/guild/stat_tile.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Sample data
// ─────────────────────────────────────────────────────────────────────────────

final _stats = [
  GuildStat(
    icon: Text(AppEmojis.members, style: TextStyle(fontSize: 18.sp)),
    value: '24',
    label: 'Members',
  ),
  GuildStat(
    icon: Text(AppEmojis.map, style: TextStyle(fontSize: 18.sp)),
    value: '186',
    label: 'Territories',
  ),
  GuildStat(
    icon: Text(AppEmojis.swords, style: TextStyle(fontSize: 18.sp)),
    value: '142',
    label: 'Raids',
  ),
  GuildStat(
    icon: Text(AppEmojis.trophy, style: TextStyle(fontSize: 18.sp)),
    value: '#2',
    label: 'Rank',
  ),
];

const _members = [
  GuildMember(avatarEmoji: AppEmojis.eagle, bgColor: Color(0xFFE8E8E8), isOnline: true),
  GuildMember(avatarEmoji: AppEmojis.wolf, bgColor: Color(0xFFE8E8E8), isOnline: true),
  GuildMember(avatarEmoji: AppEmojis.fire, bgColor: Color(0xFFFFE0CC), isOnline: true),
  GuildMember(avatarEmoji: AppEmojis.lightning, bgColor: Color(0xFFFFF9CC), isOnline: true),
  GuildMember(avatarEmoji: AppEmojis.moon, bgColor: Color(0xFFF0EAFF), isOnline: false),
  GuildMember(avatarEmoji: AppEmojis.shield, bgColor: Color(0xFFDCEEFF), isOnline: false),
];

const _extraMembers = 18;

// ─────────────────────────────────────────────────────────────────────────────
// Main card widget
// ─────────────────────────────────────────────────────────────────────────────

class GuildCard extends StatelessWidget {
  const GuildCard({
    super.key,
    this.guildName = 'StormWalkers',
    this.ownerName = 'FitWarrior',
    this.leagueName = 'Gold League',
    this.onAddTap,
  });

  final String guildName;
  final String ownerName;
  final String leagueName;
  final VoidCallback? onAddTap;

  @override
  Widget build(BuildContext context) {
    final onlineCount = _members.where((m) => m.isOnline).length;

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(26.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
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
                    Text(
                      guildName,
                      style: TextStyle(
                        color: AppColors.textNavy,
                        fontWeight: FontWeight.w800,
                        fontSize: 22.sp,
                        letterSpacing: -0.4,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Row(
                      children: [
                        Text(AppEmojis.crown, style: TextStyle(fontSize: 12.sp)),
                        SizedBox(width: 4.w),
                        Text(
                          '$ownerName · $leagueName',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Add button
              GestureDetector(
                onTap: onAddTap,
                child: Container(
                  width: 36.r,
                  height: 36.r,
                  decoration: BoxDecoration(
                    color: AppColors.tabActiveBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add_rounded,
                    color: AppColors.accentPurple,
                    size: 20.r,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 18.h),

          // ── Stats row ─────────────────────────────────────────────────────
          Row(
            children: _stats
                .map((s) => Expanded(child: StatTile(stat: s)))
                .toList(),
          ),

          SizedBox(height: 18.h),

          // ── Active members header ─────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Active Members',
                style: TextStyle(
                  color: AppColors.textNavy,
                  fontWeight: FontWeight.w700,
                  fontSize: 14.sp,
                ),
              ),
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
                    style: TextStyle(
                      color: AppColors.accentPurple,
                      fontWeight: FontWeight.w600,
                      fontSize: 13.sp,
                    ),
                  ),
                ],
              ),
            ],
          ),

          SizedBox(height: 12.h),

          // ── Member avatars row ───────────────────────────────────────────
          MemberAvatarRow(members: _members, extraCount: _extraMembers),
        ],
      ),
    );
  }
}
