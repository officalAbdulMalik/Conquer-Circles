import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/widgets/shared/animated_gradient_progress_bar.dart';

String formatNumber(int value) {
  return value.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]},',
  );
}

class SectionReveal extends StatelessWidget {
  const SectionReveal({
    super.key,
    required this.index,
    required this.entryController,
    required this.child,
  });

  final int index;
  final AnimationController entryController;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final begin = (index * 0.09).clamp(0.0, 0.7);
    final opacity = CurvedAnimation(
      parent: entryController,
      curve: Interval(begin, 1.0, curve: Curves.easeOut),
    );
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(opacity);

    return FadeTransition(
      opacity: opacity,
      child: SlideTransition(position: slide, child: child),
    );
  }
}

class ProfileProgressCard extends StatelessWidget {
  const ProfileProgressCard({
    super.key,
    required this.userName,
    required this.xpCurrent,
    required this.xpGoal,
    required this.xpProgress,
    required this.pulseValue,
  });

  final String userName;
  final int xpCurrent;
  final int xpGoal;
  final double xpProgress;
  final double pulseValue;

  @override
  Widget build(BuildContext context) {
    final sway = math.sin((pulseValue * 2 * math.pi) + 1.1) * 0.01;

    return Transform.rotate(
      angle: sway,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: const Color(0x14675FAA), width: 0.7.w),
          boxShadow: [
            BoxShadow(
              color: const Color(0x1F675FAA),
              blurRadius: 24.r,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: AppTextStyles.heading2.copyWith(fontSize: 18.sp),
                    ),
                    4.verticalSpace,
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.fillColor,
                            borderRadius: BorderRadius.circular(999.r),
                          ),
                          child: Text(
                            '⚔️ Level 15',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.brandPurple,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        8.horizontalSpace,
                        Text(
                          '${formatNumber(xpCurrent)} / ${formatNumber(xpGoal)} XP',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.brandPurple,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Progress',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    Text(
                      '${(xpProgress * 100).round()}%',
                      style: AppTextStyles.heading3,
                    ),
                  ],
                ),
              ],
            ),
            10.verticalSpace,
            AnimatedGradientProgressBar(
              value: xpProgress,
              height: 12.h,
              trackColor: AppColors.background,
              showShimmer: true,
            ),
            4.verticalSpace,
            Row(
              children: [
                Text(
                  '0 XP',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const Spacer(),
                Text(
                  '3,000 XP',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ActivityCardSection extends StatelessWidget {
  const ActivityCardSection({
    super.key,
    required this.steps,
    required this.goal,
    required this.progress,
    required this.calories,
    required this.distanceKm,
    required this.pulseValue,
  });

  final int steps;
  final int goal;
  final double progress;
  final int calories;
  final double distanceKm;
  final double pulseValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: const Color(0x14675FAA), width: 0.7.w),
        boxShadow: [
          BoxShadow(
            color: const Color(0x1F675FAA),
            blurRadius: 24.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Today's Activity", style: AppTextStyles.heading3),
          14.verticalSpace,

          SizedBox(
            height: 210.h,
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 180.w,
                    height: 180.h,
                    child: CustomPaint(
                      painter: _ActivityProgressPainter(
                        progress: progress,
                        strokeWidth: 11.w,
                      ),
                    ),
                  ),

                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formatNumber(steps),
                        style: AppTextStyles.heading1.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      5.verticalSpace,
                      Text(
                        '/ ${formatNumber(goal)} steps',
                        style: AppTextStyles.inter(
                          size: 12,
                          color: const Color(0xFF9CA3AF),
                        ),
                      ),
                      6.verticalSpace,
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.fillColor,
                          borderRadius: BorderRadius.circular(999.r),
                        ),
                        child: Text(
                          '${(progress * 100).round()}%',
                          style: AppTextStyles.style(
                            fontFamily: 'Poppins',
                            size: 14,
                            weight: FontWeight.w600,
                            color: AppColors.brandPurple,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          12.verticalSpace,
          Row(
            children: [
              Expanded(
                child: SmallStatCard(
                  title: 'Calories',
                  value: '$calories',
                  subtitle: 'kcal burned',
                  background: const Color(0xFFFFF0F0),
                  borderColor: const Color(0x26FF6B6B),
                  iconAsset: 'assets/icons/dashboard_calories_icon.svg',
                  pulseValue: pulseValue,
                ),
              ),
              12.horizontalSpace,
              Expanded(
                child: SmallStatCard(
                  title: 'Distance',
                  value: distanceKm.toStringAsFixed(1),
                  subtitle: 'km traveled',
                  background: const Color(0xFFE8FAFB),
                  borderColor: const Color(0x3353E4F3),
                  iconAsset: 'assets/icons/dashboard_distance_icon.svg',
                  pulseValue: pulseValue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActivityProgressPainter extends CustomPainter {
  _ActivityProgressPainter({required this.progress, required this.strokeWidth});

  final double progress;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final backgroundPaint = Paint()
      ..color = AppColors.background
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, backgroundPaint);

    final rect = Rect.fromCircle(center: center, radius: radius);
    final progressPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.brandPurple, AppColors.brandCyan],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ActivityProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

class SmallStatCard extends StatelessWidget {
  const SmallStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.background,
    required this.borderColor,
    required this.iconAsset,
    required this.pulseValue,
  });

  final String title;
  final String value;
  final String subtitle;
  final Color background;
  final Color borderColor;
  final String iconAsset;
  final double pulseValue;

  @override
  Widget build(BuildContext context) {
    final wave =
        1 + (math.sin((pulseValue * 2 * math.pi) + title.length) * 0.0075);

    return Transform.scale(
      scale: wave,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: borderColor, width: 0.7.w),
          boxShadow: [
            BoxShadow(
              color: const Color(0x26000000),
              blurRadius: 3.r,
              offset: Offset(0, 1.h),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SvgPicture.asset(iconAsset, width: 32.w, height: 32.h),
                8.horizontalSpace,
                Text(
                  title,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            6.verticalSpace,
            Text(
              value,
              style: AppTextStyles.heading3.copyWith(
                color: AppColors.textPrimary,
                fontSize: 22.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              subtitle,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 12.sp,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AchievementsCardSection extends StatelessWidget {
  const AchievementsCardSection({super.key});

  @override
  Widget build(BuildContext context) {
    final badges = [
      ('10K Steps', 'assets/icons/dashboard_trophy_icon.svg', true),
      ('Week Warrior', 'assets/icons/dashboard_week_warrior_icon.svg', true),
      ('Marathon', 'assets/icons/dashboard_star_icon.svg', false),
      ('Consistency', 'assets/icons/dashboard_consistency_icon.svg', true),
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: const Color(0x14675FAA), width: 0.7.w),
        boxShadow: [
          BoxShadow(
            color: const Color(0x1F675FAA),
            blurRadius: 24.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text('Achievements', style: AppTextStyles.heading3.copyWith()),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.fillColor,
                  borderRadius: BorderRadius.circular(999.r),
                ),
                child: Text(
                  '3/4 Unlocked',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
          16.verticalSpace,
          Row(
            children: [
              for (final badge in badges) ...[
                Expanded(
                  child: AchievementBadge(
                    label: badge.$1,
                    icon: badge.$2,
                    unlocked: badge.$3,
                  ),
                ),
                if (badge != badges.last) 8.horizontalSpace,
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class AchievementBadge extends StatelessWidget {
  const AchievementBadge({
    super.key,
    required this.label,
    required this.icon,
    required this.unlocked,
  });

  final String label;
  final String icon;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 52.w,
              height: 52.h,
              decoration: BoxDecoration(
                color: unlocked ? AppColors.divider : AppColors.tileNeutral,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Center(
                child: SvgPicture.asset(icon, width: 30.w, height: 30.h),
              ),
            ),
            if (unlocked)
              Positioned(
                right: -1.w,
                top: -1.h,
                child: CircleAvatar(
                  radius: 6.r,
                  backgroundColor: AppColors.success,
                  child: Icon(Icons.check, size: 8.sp, color: Colors.white),
                ),
              ),
          ],
        ),
        6.verticalSpace,
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontSize: 10.sp,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class SummaryGridSection extends StatelessWidget {
  const SummaryGridSection({
    super.key,
    required this.steps,
    required this.heartRate,
    required this.dayStreak,
    required this.energy,
    required this.pulseValue,
  });

  final int steps;
  final int heartRate;
  final int dayStreak;
  final int energy;
  final double pulseValue;

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        'Steps Today',
        formatNumber(steps),
        const Color(0xFFDDE8FB),
        AppColors.brandCyan,
      ),
      (
        'Heart Rate',
        '$heartRate bpm',
        const Color(0xFFFFE8E8),
        const Color(0xFFFB2C36),
      ),
      (
        'Day Streak',
        '$dayStreak 🔥',
        const Color(0xFFF8EEC8),
        const Color(0xFFFACC15),
      ),
      ('Energy', '$energy%', const Color(0xFFE7E5F7), const Color(0xFFFFD700)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Today's Summary", style: AppTextStyles.heading3),
        10.verticalSpace,
        GridView.builder(
          padding: EdgeInsets.zero,
          itemCount: items.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10.h,
            crossAxisSpacing: 10.w,
            childAspectRatio: 1.8,
          ),
          itemBuilder: (context, index) {
            final item = items[index];

            return Container(
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: item.$3,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: const Color(0x17000000)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 10.r,
                        backgroundColor: item.$4,
                        child: Icon(
                          Icons.person,
                          size: 12.sp,
                          color: const Color(0xFF251B56),
                        ),
                      ),
                      6.horizontalSpace,
                      Flexible(
                        child: Text(
                          item.$1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall.copyWith(
                            fontSize: 14.sp,
                            color: AppColors.bgDark,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    item.$2,
                    style: AppTextStyles.heading3.copyWith(
                      color: index == 1
                          ? const Color(0xFFFB2C36)
                          : AppColors.textPrimary,
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class DailyMissionsSection extends StatelessWidget {
  const DailyMissionsSection({
    super.key,
    required this.steps,
    required this.goal,
    required this.calories,
    required this.streak,
    required this.pulseValue,
  });

  final int steps;
  final int goal;
  final int calories;
  final int streak;
  final double pulseValue;

  @override
  Widget build(BuildContext context) {
    final walkProgress = (steps / goal).clamp(0.0, 1.0);
    final caloriesProgress = (calories / 500).clamp(0.0, 1.0);
    final streakProgress = (streak / 3).clamp(0.0, 1.0);

    final missionCards = [
      MissionData(
        emoji: '👟',
        title: 'Walk 10,000 steps',
        subtitle: 'Daily step challenge',
        progressLabel: '${formatNumber(steps)} / 10,000',
        progressPercent: '${(walkProgress * 100).round()}%',
        xp: '+100 XP',
        progress: walkProgress,
        iconGradient: const [AppColors.divider, AppColors.tileNeutral],
        tint: AppColors.brandPurple,
      ),
      MissionData(
        emoji: '🔥',
        title: 'Burn 500 calories',
        subtitle: 'Calorie burn goal',
        progressLabel: '$calories / 500',
        progressPercent: '${(caloriesProgress * 100).round()}%',
        xp: '+75 XP',
        progress: caloriesProgress,
        iconGradient: const [Color(0xFFFFF5F5), Color(0xFFFFEBEB)],
        tint: AppColors.brandPurple,
      ),
      MissionData(
        emoji: '✅',
        title: '3-day streak',
        subtitle: 'Consistency reward',
        progressLabel: '$streak / 3',
        progressPercent: '${(streakProgress * 100).round()}%',
        xp: '+50 XP',
        progress: streakProgress,
        iconGradient: const [Color(0xFFEEFFEF), Color(0xFFE2FBE7)],
        tint: const Color(0xFF16A34A),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Daily Missions', style: AppTextStyles.heading3),
            const Spacer(),
            Text(
              '${missionCards.where((e) => e.progress >= 1).length}/3 Done',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 12.sp,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        10.verticalSpace,
        ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: missionCards.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          separatorBuilder: (_, __) => 10.verticalSpace,
          itemBuilder: (context, index) {
            final mission = missionCards[index];
            final bob =
                math.sin((pulseValue * 2 * math.pi) + (index * 0.7)) * 1.0;

            return Transform.translate(
              offset: Offset(0, bob),
              child: Container(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 12.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: mission.title == '3-day streak'
                        ? const Color(0x3322C55E)
                        : const Color(0x1A675FAA),
                  ),
                  gradient: mission.title == '3-day streak'
                      ? const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [Color(0xFFFFFFFF), Color(0xFFF2FDF5)],
                        )
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0x12000000),
                      blurRadius: 3.r,
                      offset: Offset(0, 1.h),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40.w,
                          height: 40.h,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: mission.iconGradient,
                            ),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Center(
                            child: Text(
                              mission.emoji,
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontSize: 20.sp,
                              ),
                            ),
                          ),
                        ),
                        12.horizontalSpace,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                mission.title,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: mission.tint == const Color(0xFF16A34A)
                                      ? const Color(0xFF16A34A)
                                      : AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                mission.subtitle,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: const Color(0xFF9CA3AF),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 6.h,
                          ),
                          decoration: BoxDecoration(
                            color: mission.tint == const Color(0xFF16A34A)
                                ? const Color(0xFFDCFCE7)
                                : AppColors.fillColor,
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(
                              color: mission.tint == const Color(0xFF16A34A)
                                  ? const Color(0x4D22C55E)
                                  : const Color(0x33675FAA),
                            ),
                          ),
                          child: Text(
                            mission.xp,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: mission.tint,
                            ),
                          ),
                        ),
                      ],
                    ),
                    10.verticalSpace,
                    Row(
                      children: [
                        Text(
                          mission.progressLabel,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: const Color(0xFF9CA3AF),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          mission.progressPercent,
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: mission.tint,
                          ),
                        ),
                      ],
                    ),
                    6.verticalSpace,
                    AnimatedGradientProgressBar(
                      value: mission.progress,
                      height: 8.h,
                      trackColor: AppColors.divider,
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: mission.tint == const Color(0xFF16A34A)
                            ? const [AppColors.success, Color(0xFF4ADE80)]
                            : const [
                                AppColors.brandPurple,
                                AppColors.brandCyan,
                              ],
                      ),
                      showShimmer: true,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class LevelUpBannerSection extends StatelessWidget {
  const LevelUpBannerSection({super.key, required this.pulseValue});

  final double pulseValue;

  @override
  Widget build(BuildContext context) {
    final pulse = 1 + (math.sin(pulseValue * 2 * math.pi) * 0.012);

    return Transform.scale(
      scale: pulse,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [AppColors.brandPurple, Color(0xFF8B7FEA)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0x59675FAA),
              blurRadius: 20.r,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(
              '🏆',
              style: AppTextStyles.style(
                fontFamily: 'Poppins',
                size: 20,
                color: AppColors.textPrimary,
              ),
            ),
            10.horizontalSpace,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Almost there!',
                    style: AppTextStyles.style(
                      fontFamily: 'Poppins',
                      size: 14,
                      weight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Complete 2 more missions to level up',
                    style: AppTextStyles.style(
                      fontFamily: 'Inter',
                      size: 12,
                      color: const Color(0xCCFFFFFF),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StepsGlyph extends StatelessWidget {
  const StepsGlyph({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24.w,
      height: 24.h,
      child: Stack(
        children: [
          Positioned.fill(
            child: SvgPicture.asset('assets/icons/dashboard_steps_vec_1.svg'),
          ),
          Positioned(
            left: 3.w,
            top: 5.h,
            width: 16.w,
            height: 5.h,
            child: SvgPicture.asset('assets/icons/dashboard_steps_vec_2.svg'),
          ),
          Positioned(
            left: 9.w,
            top: 12.h,
            width: 6.w,
            height: 6.h,
            child: SvgPicture.asset('assets/icons/dashboard_steps_vec_3.svg'),
          ),
          Positioned(
            left: 10.w,
            top: 17.h,
            width: 4.w,
            height: 4.h,
            child: SvgPicture.asset('assets/icons/dashboard_steps_vec_4.svg'),
          ),
        ],
      ),
    );
  }
}

class MissionData {
  const MissionData({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.progressLabel,
    required this.progressPercent,
    required this.xp,
    required this.progress,
    required this.iconGradient,
    required this.tint,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final String progressLabel;
  final String progressPercent;
  final String xp;
  final double progress;
  final List<Color> iconGradient;
  final Color tint;
}
