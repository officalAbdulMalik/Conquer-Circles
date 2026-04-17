import 'package:test_steps/models/badge_model.dart';

/// State model for the step tracking provider.
/// Add attackEnergy here so the UI can read it from the same provider.
class StepState {
  final int steps;
  final Map<DateTime, int> weeklySteps;
  final int weeklyStreak;
  final int monthlyStreak;
  final int attackEnergy; // NEW — derived from steps via RPC
  final int level;
  final int xp;
  final int xpGoal;
  final int stepGoal;
  final int calories;
  final double distanceKm;
  final List<BadgeModel> badges; // NEW — real badges from Supabase
  final bool isLoading;
  final bool permissionsGranted;
  final String? error;

  const StepState({
    required this.steps,
    required this.weeklySteps,
    required this.weeklyStreak,
    required this.monthlyStreak,
    required this.attackEnergy,
    required this.level,
    required this.xp,
    required this.xpGoal,
    required this.stepGoal,
    required this.calories,
    required this.distanceKm,
    required this.badges,
    required this.isLoading,
    required this.permissionsGranted,
    this.error,
  });

  factory StepState.initial() => const StepState(
    steps: 0,
    weeklySteps: {},
    weeklyStreak: 0,
    monthlyStreak: 0,
    attackEnergy: 0,
    level: 1,
    xp: 0,
    xpGoal: 1000,
    stepGoal: 10000,
    calories: 0,
    distanceKm: 0.0,
    badges: [],
    isLoading: false,
    permissionsGranted: false,
  );

  StepState copyWith({
    int? steps,
    Map<DateTime, int>? weeklySteps,
    int? weeklyStreak,
    int? monthlyStreak,
    int? attackEnergy,
    int? level,
    int? xp,
    int? xpGoal,
    int? stepGoal,
    int? calories,
    double? distanceKm,
    List<BadgeModel>? badges,
    bool? isLoading,
    bool? permissionsGranted,
    String? error,
  }) => StepState(
    steps: steps ?? this.steps,
    weeklySteps: weeklySteps ?? this.weeklySteps,
    weeklyStreak: weeklyStreak ?? this.weeklyStreak,
    monthlyStreak: monthlyStreak ?? this.monthlyStreak,
    attackEnergy: attackEnergy ?? this.attackEnergy,
    level: level ?? this.level,
    xp: xp ?? this.xp,
    xpGoal: xpGoal ?? this.xpGoal,
    stepGoal: stepGoal ?? this.stepGoal,
    calories: calories ?? this.calories,
    distanceKm: distanceKm ?? this.distanceKm,
    badges: badges ?? this.badges,
    isLoading: isLoading ?? this.isLoading,
    permissionsGranted: permissionsGranted ?? this.permissionsGranted,
    error: error,
  );
}
