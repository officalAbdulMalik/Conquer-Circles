import 'package:test_steps/services/health_service.dart';
import 'package:test_steps/services/supabase_service.dart';

/// Connects the user's watch through the OS health store (Apple Health on iOS,
/// Health Connect on Android). Apple Watch step data is delivered to the phone
/// via Apple Health — there is no direct Bluetooth step feed — so "connecting"
/// the watch means granting Health access and reading today's steps.
class WearableService {
  WearableService(this._supabaseService, {HealthService? healthService})
    : _healthService = healthService ?? HealthService();

  final SupabaseService _supabaseService;
  final HealthService _healthService;

  /// Requests read access to step data from the OS health store.
  Future<bool> requestHealthAccess() {
    return _healthService.requestStepAuthorization();
  }

  /// Reads today's steps (includes anything the Apple Watch recorded).
  Future<HealthStepResult> fetchSteps({required int fallbackSteps}) {
    return _healthService.readTodaySteps(fallbackSteps: fallbackSteps);
  }

  Future<void> pushStepsToSupabase(int steps) async {
    final result = await _supabaseService.syncDailyStepCount(steps);
    if (result['success'] != true) {
      throw Exception(result['error']?.toString() ?? 'Step sync failed');
    }
    // Steps persisted — check whether any step badges should be claimed.
    try {
      await _supabaseService.checkAndAwardBadges('steps_synced');
    } catch (_) {
      // Badge check failures must not break the step sync itself.
    }
  }
}
