import 'dart:async';
import 'dart:developer' as developer;

import 'package:health/health.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
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

  final Health _health = Health();

  StreamSubscription<StepCount>? _pedometerSubscription;
  Timer? _syncTimer;

  int _lastSyncedSteps = -1;
  int _stepsSinceLastSync = 0;
  int? _pedometerBaseline;

  // ---------------------------------------------------------------------------
  // Initialization — called once at startup
  // ---------------------------------------------------------------------------

  /// Full initialization sequence:
  /// 1. Request permissions
  /// 2. Load last 7 days from Health + Supabase
  /// 3. Start pedometer listener
  /// 4. Start periodic background sync (every 5 min)
  Future<void> initialize() async {
    state = state.copyWith(isLoading: true, error: null);

    // 1a. Activity recognition (needed for pedometer on Android)
    final activityGranted = await _requestActivityPermission();
    if (!activityGranted) {
      state = state.copyWith(
        isLoading: false,
        error: 'Activity recognition permission denied',
        permissionsGranted: false,
      );
      return;
    }

    // 1b. Configure Health plugin
    try {
      await _health.configure();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Health configure failed: $e',
        permissionsGranted: false,
      );
      return;
    }

    // 1c. Ensure Health Connect SDK is available (Android only)
    if (!await _ensureHealthConnect()) {
      state = state.copyWith(
        isLoading: false,
        error: 'Health Connect not available',
        permissionsGranted: false,
      );
      return;
    }

    // 1d. Request Health read permission
    if (!await _requestHealthPermissions()) {
      state = state.copyWith(
        isLoading: false,
        error: 'Health permissions denied',
        permissionsGranted: false,
      );
      return;
    }

    state = state.copyWith(permissionsGranted: true);

    // 2. Load weekly data
    await _loadWeeklySteps();

    // 3. Start pedometer
    _startPedometer();

    // 4. Periodic sync every 5 minutes for background coverage
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _syncToSupabase();
    });

    state = state.copyWith(isLoading: false);
  }

  // ---------------------------------------------------------------------------
  // Permission helpers
  // ---------------------------------------------------------------------------

  Future<bool> _requestActivityPermission() async {
    final status = await Permission.activityRecognition.request();
    return status.isGranted;
  }

  Future<bool> _ensureHealthConnect() async {
    var status = await _health.getHealthConnectSdkStatus();
    developer.log('[Steps] Health Connect SDK status: $status');
    if (status != HealthConnectSdkStatus.sdkAvailable) {
      await _health.installHealthConnect();
      status = await _health.getHealthConnectSdkStatus();
    }
    return status == HealthConnectSdkStatus.sdkAvailable;
  }

  Future<bool> _requestHealthPermissions() async {
    try {
      final types = [HealthDataType.STEPS];
      final permissions = [HealthDataAccess.READ];
      final has = await _health.hasPermissions(types, permissions: permissions);
      if (has == true) return true;
      return await _health.requestAuthorization(
        types,
        permissions: permissions,
      );
    } catch (e) {
      developer.log('[Steps] Health permission error: $e');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Load weekly steps (Health + Supabase merge)
  // ---------------------------------------------------------------------------

  Future<void> _loadWeeklySteps() async {
    try {
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);
      final weekAgo = midnight.subtract(const Duration(days: 6));

      // --- Supabase data ---
      final supabaseData = await _supabaseService.getWeeklyStepsFromSupabase();

      // --- Health data ---
      final healthData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.STEPS],
        startTime: weekAgo,
        endTime: now,
      );

      // Sum Health data per day
      final Map<DateTime, int> healthSum = {};
      for (final point in healthData) {
        if (point.value is NumericHealthValue) {
          final day = DateTime(
            point.dateFrom.year,
            point.dateFrom.month,
            point.dateFrom.day,
          );
          healthSum[day] =
              (healthSum[day] ?? 0) +
              (point.value as NumericHealthValue).numericValue.toInt();
        }
      }

      // Merge: initialise all 7 days to 0, then take the max of each source
      final Map<DateTime, int> merged = {
        for (int i = 0; i < 7; i++) midnight.subtract(Duration(days: i)): 0,
      };

      supabaseData.forEach((date, steps) {
        if (merged.containsKey(date)) merged[date] = steps;
      });

      healthSum.forEach((date, steps) {
        if (merged.containsKey(date) && steps > (merged[date] ?? 0)) {
          merged[date] = steps;
        }
      });

      final todaySteps = merged[midnight] ?? 0;
      final weekStreak = _calculateStreak(merged, 5000);
      final monthStreak = _calculateMonthlyStreak(5000);

      state = state.copyWith(
        steps: todaySteps,
        weeklySteps: merged,
        weeklyStreak: weekStreak,
        monthlyStreak: monthStreak,
      );

      _lastSyncedSteps = todaySteps;
      _stepsSinceLastSync = 0;

      // Write the best value we found back to Supabase (force = true)
      await _syncToSupabase(force: true);
    } catch (e) {
      developer.log('[Steps] _loadWeeklySteps error: $e');
      state = state.copyWith(error: 'Failed to load weekly steps: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Streak helpers
  // ---------------------------------------------------------------------------

  int _calculateStreak(Map<DateTime, int> data, int goal) {
    int streak = 0;
    final today = DateTime.now();
    final midnight = DateTime(today.year, today.month, today.day);

    for (int i = 0; i < 30; i++) {
      final date = midnight.subtract(Duration(days: i));
      if ((data[date] ?? 0) >= goal) {
        streak++;
      } else if (i > 0) {
        // Allow today to still be in progress without breaking the streak
        break;
      }
    }
    return streak;
  }

  /// Monthly streak checks the last 30 days against Supabase (lazy estimate
  /// from weekly data; extend to 30-day fetch if needed).
  int _calculateMonthlyStreak(int goal) {
    // Re-uses weeklySteps for now. Replace with a 30-day fetch for accuracy.
    return _calculateStreak(state.weeklySteps, goal);
  }

  // ---------------------------------------------------------------------------
  // Supabase sync
  // ---------------------------------------------------------------------------

  /// Writes current step count to Supabase.
  /// Also converts steps → attack_energy and updates state.
  Future<void> _syncToSupabase({bool force = false}) async {
    if (!force && state.steps == _lastSyncedSteps) return;

    try {
      // upsertSteps returns the updated attack_energy from the RPC
      final attackEnergy = await _supabaseService.upsertSteps(state.steps);

      state = state.copyWith(attackEnergy: attackEnergy);
      _lastSyncedSteps = state.steps;
      _stepsSinceLastSync = 0;

      developer.log(
        '[Steps] Synced ${state.steps} steps, '
        'attack_energy=$attackEnergy',
      );
    } catch (e) {
      developer.log('[Steps] _syncToSupabase error: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Pedometer
  // ---------------------------------------------------------------------------

  void _startPedometer() {
    try {
      _pedometerSubscription = Pedometer.stepCountStream.listen(
        _onPedometerUpdate,
        onError: (Object error) {
          developer.log('[Steps] Pedometer error: $error');
          state = state.copyWith(error: 'Pedometer error: $error');
        },
      );
    } catch (e) {
      developer.log('[Steps] Failed to start pedometer: $e');
      state = state.copyWith(error: 'Failed to start pedometer: $e');
    }
  }

  void _onPedometerUpdate(StepCount event) {
    final newTotal = event.steps;

    if (_pedometerBaseline == null) {
      _pedometerBaseline = newTotal;
      developer.log('[Steps] Pedometer baseline: $newTotal');
      return;
    }

    if (newTotal > _pedometerBaseline!) {
      final delta = newTotal - _pedometerBaseline!;
      _pedometerBaseline = newTotal;

      state = state.copyWith(steps: state.steps + delta);
      _stepsSinceLastSync += delta;

      // Sync after every 10 new steps to avoid spamming
      if (_stepsSinceLastSync >= 10) {
        _syncToSupabase();
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Manual updates
  // ---------------------------------------------------------------------------

  /// Syncs energy from external sources (e.g. after an attack RPC)
  void updateEnergy(int newEnergy) {
    state = state.copyWith(attackEnergy: newEnergy);
  }

  // ---------------------------------------------------------------------------
  // Manual refresh (pull-to-refresh or foreground resume)
  // ---------------------------------------------------------------------------

  /// Call this from the UI when the screen comes back into focus,
  /// e.g. in onResume / AppLifecycleListener.
  Future<void> refresh() => _loadWeeklySteps();

  // ---------------------------------------------------------------------------
  // Dispose
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    _pedometerSubscription?.cancel();
    _syncTimer?.cancel();
    super.dispose();
  }
}
