/// State model for the step tracking provider.
/// Add attackEnergy here so the UI can read it from the same provider.
class StepState {
  final int steps;
  final Map<DateTime, int> weeklySteps;
  final int weeklyStreak;
  final int monthlyStreak;
  final int attackEnergy; // NEW — derived from steps via RPC
  final bool isLoading;
  final bool permissionsGranted;
  final String? error;

  const StepState({
    required this.steps,
    required this.weeklySteps,
    required this.weeklyStreak,
    required this.monthlyStreak,
    required this.attackEnergy,
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
    isLoading: false,
    permissionsGranted: false,
  );

  StepState copyWith({
    int? steps,
    Map<DateTime, int>? weeklySteps,
    int? weeklyStreak,
    int? monthlyStreak,
    int? attackEnergy,
    bool? isLoading,
    bool? permissionsGranted,
    String? error,
  }) => StepState(
    steps: steps ?? this.steps,
    weeklySteps: weeklySteps ?? this.weeklySteps,
    weeklyStreak: weeklyStreak ?? this.weeklyStreak,
    monthlyStreak: monthlyStreak ?? this.monthlyStreak,
    attackEnergy: attackEnergy ?? this.attackEnergy,
    isLoading: isLoading ?? this.isLoading,
    permissionsGranted: permissionsGranted ?? this.permissionsGranted,
    error: error,
  );
}
