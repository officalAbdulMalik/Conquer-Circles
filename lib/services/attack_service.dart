import 'dart:async';
import 'dart:developer' as developer;
import 'package:riverpod/legacy.dart';
import '../models/steps_model.dart';
import '../services/supabase_service.dart';

/// Exposes [StepState] to the widget tree.
/// Instantiate SupabaseService however your DI is set up — here we new it
/// directly for simplicity; swap for ref.read(supabaseServiceProvider) if
/// you have a Riverpod provider for it.
final stepProvider = StateNotifierProvider<StepNotifier, StepState>((ref) {
  return StepNotifier(SupabaseService());
});

class StepNotifier extends StateNotifier<StepState> {
  final SupabaseService _supabaseService;

  StepNotifier(this._supabaseService) : super(StepState.initial()) {
    initialize();
  }

  Future<void> initialize() async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      permissionsGranted: true,
    );

    await _loadWeeklySteps();

    state = state.copyWith(isLoading: false);
  }

  Future<void> _loadWeeklySteps() async {
    try {
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);

      final supabaseData = await _supabaseService.getWeeklyStepsFromSupabase();
      final todaySteps = supabaseData[midnight] ?? 0;
      final attackEnergy = await _supabaseService.getAttackEnergy();

      state = state.copyWith(
        steps: todaySteps,
        weeklySteps: supabaseData,
        attackEnergy: attackEnergy,
        permissionsGranted: true,
        error: null,
      );
    } catch (e) {
      developer.log('[Steps] _loadWeeklySteps error: $e');
      state = state.copyWith(error: 'Failed to load weekly steps: $e');
    }
  }

  /// Syncs energy from external sources (e.g. after an attack RPC)
  void updateEnergy(int newEnergy) {
    state = state.copyWith(attackEnergy: newEnergy);
  }

  /// Call this from the UI when the screen comes back into focus,
  /// e.g. in onResume / AppLifecycleListener.
  Future<void> refresh() => _loadWeeklySteps();
}
