import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:test_steps/core/constants/app_emojis.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/features/social/models/leaderboard_user.dart';
import 'package:test_steps/widgets/shared/animated_gradient_progress_bar.dart';
import 'package:test_steps/widgets/shared/user_avatar.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Sample data
// ─────────────────────────────────────────────────────────────────────────────

const _users = [
  LeaderboardUser(
    rank: 1,
    username: 'FitWarrior',
    score: 142,
    progressValue: 0.90,
    avatarEmoji: AppEmojis.eagle,
    avatarBgColor: AppColors.avatarNeutral,
    badgeEmoji: AppEmojis.crown,
    isOnline: true,
  ),
  LeaderboardUser(
    rank: 2,
    username: 'IronStrider',
    score: 128,
    progressValue: 0.75,
    avatarEmoji: AppEmojis.wolf,
    avatarBgColor: AppColors.avatarNeutral,
    isOnline: true,
  ),
  LeaderboardUser(
    rank: 3,
    username: 'SwiftBlaze',
    score: 98,
    progressValue: 0.58,
    avatarEmoji: AppEmojis.fire,
    avatarBgColor: AppColors.avatarWarm,
    isOnline: false,
  ),
  LeaderboardUser(
    rank: 4,
    username: 'TitanWalk',
    score: 95,
    progressValue: 0.54,
    avatarEmoji: AppEmojis.shield,
    avatarBgColor: AppColors.avatarCool,
    isOnline: true,
  ),
  LeaderboardUser(
    rank: 5,
    username: 'NeonPath',
    score: 85,
    progressValue: 0.44,
    avatarEmoji: AppEmojis.lightning,
    avatarBgColor: AppColors.avatarSun,
    isOnline: true,
  ),
  LeaderboardUser(
    rank: 6,
    username: 'ShadowStep',
    score: 72,
    progressValue: 0.35,
    avatarEmoji: AppEmojis.moon,
    avatarBgColor: AppColors.avatarLavender,
    isOnline: false,
  ),
];

class LeaderboardCard extends StatefulWidget {
  const LeaderboardCard({super.key});

  @override
  State<LeaderboardCard> createState() => _LeaderboardCardState();
}

class _LeaderboardCardState extends State<LeaderboardCard> {
  int _selectedTab = 0;

  final _tabs = [
    ('Tiles', AppEmojis.star),
    ('Steps', AppEmojis.steps),
    ('Raids', AppEmojis.raids),
    ('Energy', AppEmojis.lightning),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24.r),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 12.w, 8.h),
            child: Row(
              children: [
                SvgPicture.asset('assets/icons/arrow.svg'),
                SizedBox(width: 6.w),
                Text(
                  'Leaderboard',
                  style: AppTextStyles.cardTitle.copyWith(
                    fontSize: 16.sp,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(_tabs.length, (i) {
                        final (label, icon) = _tabs[i];
                        final active = i == _selectedTab;
                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedTab = i);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            margin: EdgeInsets.only(right: 6.w),
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 5.h,
                            ),
                            decoration: BoxDecoration(
                              color: active
                                  ? AppColors.tabActiveBg
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20).r,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  icon,
                                  style: AppTextStyles.inter(
                                    size: 11,
                                    color: active
                                        ? AppColors.accentPurple
                                        : AppColors.textSecondary,
                                  ),
                                ),
                                SizedBox(width: 3.w),
                                Text(
                                  label,
                                  style: AppTextStyles.inter(
                                    size: 12,
                                    weight: active
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: active
                                        ? AppColors.accentPurple
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 4.h),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _users.length,
            itemBuilder: (_, i) => Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 5.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 32.w,
                        child: _users[i].rank <= 3
                            ? MedalBadge(rank: _users[i].rank)
                            : Text(
                                '#${_users[i].rank}',
                                style: AppTextStyles.inter(
                                  size: 13,
                                  color: AppColors.textSecondary,
                                  weight: FontWeight.w600,
                                ),
                              ),
                      ),
                      SizedBox(width: 6.w),
                      UserAvatar(
                        avatarEmoji: _users[i].avatarEmoji,
                        bgColor: _users[i].avatarBgColor,
                        isOnline: _users[i].isOnline,
                        badgeEmoji: _users[i].badgeEmoji,
                        size: 40,
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: _users[i].username,
                                style: AppTextStyles.poppins(
                                  size: 14,
                                  color: AppColors.textNavy,
                                  weight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(
                                text: '  ${_users[i].badgeEmoji ?? AppEmojis.emptyBadge}',
                                style: TextStyle(fontSize: 13.sp),
                              ),
                            ],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${_users[i].score}',
                        style: AppTextStyles.poppins(
                          size: 16,
                          color: AppColors.accentIndigo,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  8.verticalSpace,
                  Padding(
                    padding: EdgeInsets.only(left: 38.w),
                    child: AnimatedGradientProgressBar(
                      value: _users[i].progressValue,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 8.h),
        ],
      ),
    );
  }
}

class MedalBadge extends StatelessWidget {
  const MedalBadge({super.key, required this.rank});

  final int rank;

  Color get _medalColor {
    if (rank == 1) return AppColors.gold;
    if (rank == 2) return AppColors.silver;
    return AppColors.bronze;
  }

  @override
  Widget build(BuildContext context) {
    final color = _medalColor;
    return Container(
      width: 26.r,
      height: 26.r,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.5.r),
      ),
      child: Center(
        child: Icon(Icons.emoji_events_rounded, color: color, size: 14.r),
      ),
    );
  }
}
