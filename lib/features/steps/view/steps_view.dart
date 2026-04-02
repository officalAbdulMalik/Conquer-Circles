import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:test_steps/services/health_service.dart';
import 'package:test_steps/services/supabase_service.dart';
import 'package:test_steps/widgets/shared/animated_gradient_progress_bar.dart';

class StepsView extends ConsumerStatefulWidget {
  const StepsView({super.key});

  @override
  ConsumerState<StepsView> createState() => _StepsViewState();
}

class _StepsViewState extends ConsumerState<StepsView>
    with TickerProviderStateMixin {
  late final AnimationController _entryController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 950),
  )..forward();

  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1700),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _entryController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stepState = ref.watch(stepProvider);
    final userName =
        SupabaseService().currentUser?.email?.split('@')[0] ?? 'FitWarrior_92';

    final int steps = stepState.steps;
    const int goal = 10000;
    final double stepProgress = (steps / goal).clamp(0, 1);
    final int xpCurrent = (steps * 0.287).round().clamp(0, 3000);
    const int xpGoal = 3000;
    final double xpProgress = (xpCurrent / xpGoal).clamp(0, 1);
    final int calories = (steps * 0.04).round();
    final double distanceKm = (steps * 0.00073);
    final int streak = stepState.weeklyStreak;
    final int energy = ((stepState.attackEnergy / 400) * 100).round().clamp(
      0,
      100,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, _) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection(
                    index: 0,
                    child: _topGreeting(userName: userName),
                  ),
                  const SizedBox(height: 20),
                  _buildSection(
                    index: 1,
                    child: _profileCard(
                      userName: userName,
                      xpCurrent: xpCurrent,
                      xpGoal: xpGoal,
                      xpProgress: xpProgress,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSection(
                    index: 2,
                    child: _activityCard(
                      steps: steps,
                      goal: goal,
                      progress: stepProgress,
                      calories: calories,
                      distanceKm: distanceKm,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSection(index: 3, child: _achievementsCard()),
                  const SizedBox(height: 18),
                  _buildSection(
                    index: 4,
                    child: _summaryGrid(
                      steps: steps,
                      heartRate: 82,
                      dayStreak: streak,
                      energy: energy,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _buildSection(
                    index: 5,
                    child: _dailyMissions(
                      steps: steps,
                      goal: goal,
                      calories: calories,
                      streak: streak,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildSection(index: 6, child: _levelUpBanner()),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSection({required int index, required Widget child}) {
    final begin = (index * 0.09).clamp(0.0, 0.7);
    final opacity = CurvedAnimation(
      parent: _entryController,
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

  Widget _topGreeting({required String userName}) {
    final bob = math.sin((_pulseController.value * 2 * math.pi) + 0.4) * 1.4;

    return Transform.translate(
      offset: Offset(0, bob),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Good morning! 👋',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 31,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2D2D2D),
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "Let's crush today's goals",
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          const Spacer(),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 56,
                height: 56,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF675FAA), Color(0xFF53E4F3)],
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x59675FAA),
                      blurRadius: 16,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/icons/dashboard_profile_avatar.svg',
                      width: 36,
                      height: 36,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: -3,
                bottom: -2,
                child: Container(
                  width: 29,
                  height: 29,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white, width: 1.9),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x80FFA500),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${(userName.length % 20) + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _profileCard({
    required String userName,
    required int xpCurrent,
    required int xpGoal,
    required double xpProgress,
  }) {
    final sway = math.sin((_pulseController.value * 2 * math.pi) + 1.1) * 0.01;

    return Transform.rotate(
      angle: sway,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0x14675FAA), width: 0.7),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F675FAA),
              blurRadius: 24,
              offset: Offset(0, 4),
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
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D2D2D),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F3FF),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            '⚔️ Level 15',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: Color(0xFF675FAA),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_formatNumber(xpCurrent)} / ${_formatNumber(xpGoal)} XP',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: Color(0xFF675FAA),
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
                    const Text(
                      'Progress',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    Text(
                      '${(xpProgress * 100).round()}%',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        color: Color(0xFF675FAA),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            AnimatedGradientProgressBar(
              value: xpProgress,
              height: 12,
              trackColor: const Color(0xFFF0EEFF),
              showShimmer: true,
            ),
            const SizedBox(height: 4),
            const Row(
              children: [
                Text(
                  '0 XP',
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'Inter',
                    color: Color(0xFF9CA3AF),
                  ),
                ),
                Spacer(),
                Text(
                  '3,000 XP',
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'Inter',
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _activityCard({
    required int steps,
    required int goal,
    required double progress,
    required int calories,
    required double distanceKm,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x14675FAA), width: 0.7),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F675FAA),
            blurRadius: 24,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Today's Activity",
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 25,
              color: Color(0xFF2D2D2D),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 210,
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 208,
                    height: 208,
                    child: SvgPicture.asset(
                      'assets/icons/dashboard_steps_ring.svg',
                    ),
                  ),
                  Positioned(
                    top: 34,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFF53E4F3),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Center(child: _stepsGlyph()),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatNumber(steps),
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 42,
                          color: Color(0xFF2D2D2D),
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                        ),
                      ),
                      Text(
                        '/ ${_formatNumber(goal)} steps',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F3FF),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${(progress * 100).round()}%',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            color: Color(0xFF675FAA),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _smallStatCard(
                  title: 'Calories',
                  value: '$calories',
                  subtitle: 'kcal burned',
                  background: const Color(0xFFFFF0F0),
                  borderColor: const Color(0x26FF6B6B),
                  iconAsset: 'assets/icons/dashboard_calories_icon.svg',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _smallStatCard(
                  title: 'Distance',
                  value: distanceKm.toStringAsFixed(1),
                  subtitle: 'km traveled',
                  background: const Color(0xFFE8FAFB),
                  borderColor: const Color(0x3353E4F3),
                  iconAsset: 'assets/icons/dashboard_distance_icon.svg',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _smallStatCard({
    required String title,
    required String value,
    required String subtitle,
    required Color background,
    required Color borderColor,
    required String iconAsset,
  }) {
    final wave =
        1 +
        (math.sin((_pulseController.value * 2 * math.pi) + title.length) *
            0.0075);

    return Transform.scale(
      scale: wave,
      child: Container(
        height: 123,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 0.7),
          boxShadow: const [
            BoxShadow(
              color: Color(0x26000000),
              blurRadius: 3,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SvgPicture.asset(iconAsset, width: 32, height: 32),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2D2D2D),
                height: 1.2,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _achievementsCard() {
    final badges = [
      ('10K Steps', 'assets/icons/dashboard_trophy_icon.svg', true),
      ('Week Warrior', 'assets/icons/dashboard_week_warrior_icon.svg', true),
      ('Marathon', 'assets/icons/dashboard_star_icon.svg', false),
      ('Consistency', 'assets/icons/dashboard_consistency_icon.svg', true),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x14675FAA), width: 0.7),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F675FAA),
            blurRadius: 24,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'Achievements',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D2D2D),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3FF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  '3/4 Unlocked',
                  style: TextStyle(
                    color: Color(0xFF675FAA),
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (final badge in badges) ...[
                Expanded(
                  child: _achievementBadge(
                    label: badge.$1,
                    icon: badge.$2,
                    unlocked: badge.$3,
                  ),
                ),
                if (badge != badges.last) const SizedBox(width: 8),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _achievementBadge({
    required String label,
    required String icon,
    required bool unlocked,
  }) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: unlocked
                    ? const Color(0xFFF3F4F6)
                    : const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: SvgPicture.asset(icon, width: 30, height: 30),
              ),
            ),
            if (unlocked)
              const Positioned(
                right: -1,
                top: -1,
                child: CircleAvatar(
                  radius: 6,
                  backgroundColor: Color(0xFF22C55E),
                  child: Icon(Icons.check, size: 8, color: Colors.white),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  Widget _summaryGrid({
    required int steps,
    required int heartRate,
    required int dayStreak,
    required int energy,
  }) {
    final items = [
      (
        'Steps Today',
        _formatNumber(steps),
        const Color(0xFFDDE8FB),
        const Color(0xFF53E4F3),
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
        const Text(
          "Today's Summary",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 28,
            color: Color(0xFF2D2D2D),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          itemCount: items.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.25,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            final float =
                math.sin((_pulseController.value * 2 * math.pi) + index * 0.8) *
                1.5;

            return Transform.translate(
              offset: Offset(0, float),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: item.$3,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0x17000000)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 10,
                          backgroundColor: item.$4,
                          child: const Icon(
                            Icons.person,
                            size: 12,
                            color: Color(0xFF251B56),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            item.$1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      item.$2,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 31,
                        fontWeight: FontWeight.w700,
                        color: index == 1
                            ? const Color(0xFFFB2C36)
                            : const Color(0xFF675FAA),
                        height: 1,
                      ),
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

  Widget _dailyMissions({
    required int steps,
    required int goal,
    required int calories,
    required int streak,
  }) {
    final walkProgress = (steps / goal).clamp(0.0, 1.0);
    final caloriesProgress = (calories / 500).clamp(0.0, 1.0);
    final streakProgress = (streak / 3).clamp(0.0, 1.0);

    final missionCards = [
      _MissionData(
        emoji: '👟',
        title: 'Walk 10,000 steps',
        subtitle: 'Daily step challenge',
        progressLabel: '${_formatNumber(steps)} / 10,000',
        progressPercent: '${(walkProgress * 100).round()}%',
        xp: '+100 XP',
        progress: walkProgress,
        iconGradient: const [Color(0xFFF3F4F6), Color(0xFFE5E7EB)],
        tint: const Color(0xFF675FAA),
      ),
      _MissionData(
        emoji: '🔥',
        title: 'Burn 500 calories',
        subtitle: 'Calorie burn goal',
        progressLabel: '$calories / 500',
        progressPercent: '${(caloriesProgress * 100).round()}%',
        xp: '+75 XP',
        progress: caloriesProgress,
        iconGradient: const [Color(0xFFFFF5F5), Color(0xFFFFEBEB)],
        tint: const Color(0xFF675FAA),
      ),
      _MissionData(
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
            const Text(
              'Daily Missions',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 28,
                color: Color(0xFF2D2D2D),
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              '${missionCards.where((e) => e.progress >= 1).length}/3 Done',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: Color(0xFF675FAA),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ListView.separated(
          itemCount: missionCards.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final mission = missionCards[index];
            final bob =
                math.sin(
                  (_pulseController.value * 2 * math.pi) + (index * 0.7),
                ) *
                1.0;

            return Transform.translate(
              offset: Offset(0, bob),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
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
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x12000000),
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: mission.iconGradient,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Text(
                              mission.emoji,
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                mission.title,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: mission.tint == const Color(0xFF16A34A)
                                      ? const Color(0xFF16A34A)
                                      : const Color(0xFF2D2D2D),
                                ),
                              ),
                              Text(
                                mission.subtitle,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  color: Color(0xFF9CA3AF),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: mission.tint == const Color(0xFF16A34A)
                                ? const Color(0xFFDCFCE7)
                                : const Color(0xFFF5F3FF),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: mission.tint == const Color(0xFF16A34A)
                                  ? const Color(0x4D22C55E)
                                  : const Color(0x33675FAA),
                            ),
                          ),
                          child: Text(
                            mission.xp,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: mission.tint,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          mission.progressLabel,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          mission.progressPercent,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: mission.tint,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    AnimatedGradientProgressBar(
                      value: mission.progress,
                      height: 8,
                      trackColor: const Color(0xFFF3F4F6),
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: mission.tint == const Color(0xFF16A34A)
                            ? const [Color(0xFF22C55E), Color(0xFF4ADE80)]
                            : const [Color(0xFF675FAA), Color(0xFF53E4F3)],
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

  Widget _levelUpBanner() {
    final pulse = 1 + (math.sin(_pulseController.value * 2 * math.pi) * 0.012);

    return Transform.scale(
      scale: pulse,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFF675FAA), Color(0xFF8B7FEA)],
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x59675FAA),
              blurRadius: 20,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          children: [
            Text('🏆', style: TextStyle(fontSize: 20)),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Almost there!',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Complete 2 more missions to level up',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: Color(0xCCFFFFFF),
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

  Widget _stepsGlyph() {
    return SizedBox(
      width: 24,
      height: 24,
      child: Stack(
        children: [
          Positioned.fill(
            child: SvgPicture.asset('assets/icons/dashboard_steps_vec_1.svg'),
          ),
          Positioned(
            left: 3,
            top: 5,
            width: 16,
            height: 5,
            child: SvgPicture.asset('assets/icons/dashboard_steps_vec_2.svg'),
          ),
          Positioned(
            left: 9,
            top: 12,
            width: 6,
            height: 6,
            child: SvgPicture.asset('assets/icons/dashboard_steps_vec_3.svg'),
          ),
          Positioned(
            left: 10,
            top: 17,
            width: 4,
            height: 4,
            child: SvgPicture.asset('assets/icons/dashboard_steps_vec_4.svg'),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
  }
}

class _MissionData {
  const _MissionData({
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
