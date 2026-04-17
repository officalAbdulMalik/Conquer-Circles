import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:test_steps/core/constants/app_emojis.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/features/social/models/leaderboard_user.dart';
import 'package:test_steps/widgets/shared/animated_gradient_progress_bar.dart';
import 'package:test_steps/widgets/shared/user_avatar.dart';

class LeaderboardCard extends StatefulWidget {
  const LeaderboardCard({super.key, this.isMemebers, this.leaderboard});

  final bool? isMemebers;
  final List<dynamic>? leaderboard;

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

  int _getScore(Map<String, dynamic> user, int tab) {
    if (tab == 0) return (user['territories'] as num?)?.toInt() ?? 0;
    if (tab == 1) return (user['steps'] as num?)?.toInt() ?? 0;
    if (tab == 2) return (user['raids_won'] as num?)?.toInt() ?? 0;
    if (tab == 3) return (user['attack_energy'] as num?)?.toInt() ?? 0;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    List<LeaderboardUser> displayUsers = [];
    if (widget.leaderboard != null) {
      // filter valid entries and parse
      final lb = List<Map<String, dynamic>>.from(widget.leaderboard!);
      
      // Sort based on selected tab
      lb.sort((a, b) => _getScore(b, _selectedTab).compareTo(_getScore(a, _selectedTab)));

      int maxScore = 1;
      if (lb.isNotEmpty) {
        maxScore = _getScore(lb.first, _selectedTab);
        if (maxScore <= 0) maxScore = 1; // avoid division by zero
      }

      for (int i = 0; i < lb.length; i++) {
        final m = lb[i];
        final score = _getScore(m, _selectedTab);
        displayUsers.add(LeaderboardUser(
          rank: i + 1,
          username: m['username']?.toString() ?? 'User',
          score: score,
          progressValue: (score / maxScore).clamp(0.0, 1.0),
          avatarEmoji: AppEmojis.eagle, // default
          avatarBgColor: AppColors.avatarNeutral, // default
          isOnline: true,
        ));
      }
    }

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
                if (widget.isMemebers == false) ...[
                  SvgPicture.asset('assets/icons/arrow.svg'),
                  6.horizontalSpace,
                ],
                Text(
                  widget.isMemebers == true ? 'Members' : 'Leaderboard',
                  style: AppTextStyles.heading3,
                ),
                if (widget.isMemebers == true) ...[
                  10.horizontalSpace,
                  Text(
                    '100',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.accentPurple,
                    ),
                  ),
                ],
                if (widget.isMemebers != true) ...[
                  12.horizontalSpace,
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
                                    style: AppTextStyles.bodySmall.copyWith(
                                      fontSize: 12.sp,
                                      color: active
                                          ? AppColors.accentPurple
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                  3.horizontalSpace,
                                  Text(
                                    label,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      fontSize: 14.sp,
                                      fontWeight: active
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
              ],
            ),
          ),
          4.verticalSpace,
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayUsers.length,
            itemBuilder: (_, i) => Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 5.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 32.w,
                        child: displayUsers[i].rank <= 3
                            ? MedalBadge(rank: displayUsers[i].rank)
                            : Text(
                                '#${displayUsers[i].rank}',
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                      SizedBox(width: 6.w),
                      UserAvatar(
                        avatarEmoji: displayUsers[i].avatarEmoji,
                        bgColor: displayUsers[i].avatarBgColor,
                        isOnline: displayUsers[i].isOnline,
                        badgeEmoji: displayUsers[i].badgeEmoji,
                        size: 40,
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: displayUsers[i].username,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(
                                text:
                                    '  ${displayUsers[i].badgeEmoji ?? AppEmojis.emptyBadge}',
                                style: TextStyle(fontSize: 13.sp),
                              ),
                            ],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${displayUsers[i].score}',
                        style: AppTextStyles.heading3.copyWith(
                          fontSize: 18.sp,
                          color: AppColors.accentIndigo,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  8.verticalSpace,
                  Padding(
                    padding: EdgeInsets.only(left: 38.w),
                    child: AnimatedGradientProgressBar(
                      value: displayUsers[i].progressValue,
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
