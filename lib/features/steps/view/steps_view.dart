import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:test_steps/core/theme/app_spacing.dart';
import 'package:test_steps/features/steps/widgets/steps_dashboard_sections.dart';
import 'package:test_steps/services/health_service.dart';
import 'package:test_steps/services/supabase_service.dart';

class StepsView extends ConsumerStatefulWidget {
  const StepsView({super.key});

  @override
  ConsumerState<StepsView> createState() => _StepsViewState();
}

class _StepsViewState extends ConsumerState<StepsView>
    with TickerProviderStateMixin<StepsView> {
  late final AnimationController _pulseController;
  late final AnimationController _entryController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _entryController.dispose();
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
    final double distanceKm = steps * 0.00073;
    final int streak = stepState.weeklyStreak;
    final int energy = ((stepState.attackEnergy / 400) * 100).round().clamp(
      0,
      100,
    );
    final pulseValue = _pulseController.value;
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: AppSpacing.pagePadding,
          child: TopGreetingSection(userName: userName, pulseValue: pulseValue),
        ),
      ),
      body: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, _) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: AppSpacing.pagePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: MediaQuery.of(context).padding.top + 20.h),

                ProfileCardSection(
                  userName: userName,
                  xpCurrent: xpCurrent,
                  xpGoal: xpGoal,
                  xpProgress: xpProgress,
                  pulseValue: pulseValue,
                ),
                20.verticalSpace,
                ActivityCardSection(
                  steps: steps,
                  goal: goal,
                  progress: stepProgress,
                  calories: calories,
                  distanceKm: distanceKm,
                  pulseValue: pulseValue,
                ),
                20.verticalSpace,
                const AchievementsCardSection(),
                18.verticalSpace,
                SummaryGridSection(
                  steps: steps,
                  heartRate: 82,
                  dayStreak: streak,
                  energy: energy,
                  pulseValue: pulseValue,
                ),
                18.verticalSpace,
                DailyMissionsSection(
                  steps: steps,
                  goal: goal,
                  calories: calories,
                  streak: streak,
                  pulseValue: pulseValue,
                ),
                14.verticalSpace,
                LevelUpBannerSection(pulseValue: pulseValue),
              ],
            ),
          );
        },
      ),
    );
  }
}
