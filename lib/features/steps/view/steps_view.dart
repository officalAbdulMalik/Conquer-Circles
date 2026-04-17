import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_spacing.dart';
import 'package:test_steps/features/steps/widgets/steps_dashboard_sections.dart';
import 'package:test_steps/providers/profile_provider.dart';
import 'package:test_steps/services/health_service.dart';
import 'package:test_steps/services/notification_service.dart';
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
    Future.microtask(() {
      ref.read(stepProvider.notifier).loadWeeklySteps();
    });
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
    final int goal = stepState.stepGoal;
    final double stepProgress = (steps / (goal > 0 ? goal : 10000)).clamp(0, 1);

    final int xpCurrent = stepState.xp;
    final int xpGoal = stepState.xpGoal;
    final int level = stepState.level;
    final double xpProgress = (xpCurrent / (xpGoal > 0 ? xpGoal : 3000)).clamp(
      0,
      1,
    );

    final int calories = stepState.calories;
    final double distanceKm = stepState.distanceKm;
    final int streak = stepState.weeklyStreak;
    final int energy = stepState.attackEnergy; // Directly use energy from state
    final pulseValue = _pulseController.value;
    return Scaffold(
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
                ProfileProgressCard(
                  userName: userName,
                  xpCurrent: xpCurrent,
                  xpGoal: xpGoal,
                  xpProgress: xpProgress,
                  level: level,
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
                AchievementsCardSection(badges: stepState.badges),
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
                14.verticalSpace,
                // LevelUpBannerSection(pulseValue: pulseValue),
                30.verticalSpace,
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Checking for new badges...'),
                        ),
                      );
                      // call the function
                      await SupabaseService().checkAndAwardBadges('test_award');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Badge check complete! Check your profile.',
                            ),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.emoji_events),
                    label: const Text('🏆 Test Achievements'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandPurple,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 24.w,
                        vertical: 12.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ),
                ),
                50.verticalSpace,
              ],
            ),
          );
        },
      ),
    );
  }
}
