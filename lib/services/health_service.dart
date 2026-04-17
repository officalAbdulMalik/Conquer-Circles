import 'dart:async';
import 'dart:developer' as developer;
import 'package:riverpod/legacy.dart';
import 'package:test_steps/models/steps_model.dart';
import 'package:test_steps/services/supabase_service.dart';
import 'package:test_steps/models/badge_model.dart';

final stepProvider = StateNotifierProvider<StepNotifier, StepState>((ref) {
  return StepNotifier(SupabaseService());
});

class StepNotifier extends StateNotifier<StepState> {
  final SupabaseService _supabaseService;

  StepNotifier(this._supabaseService) : super(StepState.initial());

  /// Load today and weekly step data from Supabase only.
  Future<void> loadWeeklySteps() async {
    developer.log('loadWeeklySteps');

    try {
      state = state.copyWith(
        isLoading: true,
        error: null,
        permissionsGranted: true,
      );

      final dashboardData = await _supabaseService.getStepsDashboardData();
      developer.log('Fetched dashboard data from Supabase: $dashboardData');

      final profile = dashboardData['profile'] as Map<String, dynamic>? ?? {};
      final today = dashboardData['today'] as Map<String, dynamic>? ?? {};
      final weeklyRaw = dashboardData['weekly_steps'] as List? ?? [];
      final badgesRaw = dashboardData['badges'] as List? ?? [];

      final Map<DateTime, int> weeklySteps = {};
      for (final row in weeklyRaw) {
        final date = DateTime.parse(row['date'] as String);
        final normalizedDate = DateTime(date.year, date.month, date.day);
        weeklySteps[normalizedDate] = row['steps'] as int;
      }

      final badges = badgesRaw.map((b) => BadgeModel.fromJson(b as Map<String, dynamic>)).toList();

      state = state.copyWith(
        steps: today['steps'] as int? ?? 0,
        calories: today['calories'] as int? ?? 0,
        distanceKm: (today['distance_km'] as num?)?.toDouble() ?? 0.0,
        level: profile['level'] as int? ?? 1,
        xp: profile['xp'] as int? ?? 0,
        xpGoal: profile['xp_goal'] as int? ?? 1000,
        stepGoal: profile['step_goal'] as int? ?? 10000,
        weeklyStreak: profile['streak'] as int? ?? 0,
        attackEnergy: profile['attack_energy'] as int? ?? 0,
        weeklySteps: weeklySteps,
        badges: badges,
        isLoading: false,
        permissionsGranted: true,
      );
    } catch (e) {
      developer.log('Failed to load dashboard data: $e');
      final errorMessage = e.toString();

      if (errorMessage.contains('Session mismatch') ||
          errorMessage.contains('No active session')) {
        state = state.copyWith(
          isLoading: false,
          error: 'Session expired. Please log in again.',
          permissionsGranted: true,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to load dashboard data',
          permissionsGranted: true,
        );
      }
    }
  }
}
