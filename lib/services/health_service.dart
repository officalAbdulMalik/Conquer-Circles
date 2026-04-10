import 'dart:async';
import 'dart:developer' as developer;

// Removed unused import: package:flutter_riverpod/flutter_riverpod.dart
import 'package:health/health.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:riverpod/legacy.dart';
import 'package:test_steps/services/supabase_service.dart';
import 'package:test_steps/services/badge_service.dart';
import 'package:test_steps/models/steps_model.dart';
// Removed unused import: dart:io

final stepProvider = StateNotifierProvider<StepNotifier, StepState>((ref) {
  return StepNotifier(SupabaseService(), BadgeService());
});

class StepNotifier extends StateNotifier<StepState> {
  final SupabaseService _supabaseService;
  final BadgeService _badgeService;

  StepNotifier(this._supabaseService, this._badgeService)
    : super(StepState.initial()) {
    // initialize();  
  }

  final Health _health = Health();
  StreamSubscription<StepCount>? _pedometerSubscription;
  StreamSubscription? _healthObserverSubscription;
  Timer? _syncTimer;

  int _lastSyncedSteps = -1;
  int _stepsSinceLastSync = 0;
  int? _pedometerBaseline;

  Future<void> initialize() async {
    await Future.microtask(() {});
    state = state.copyWith(isLoading: true, error: null);

    print('initialize');

    // 1. Request activity recognition permission (for pedometer)
    final activityGranted = await _requestActivityPermission();
    if (!activityGranted) {
      state = state.copyWith(
        isLoading: false,
        error: 'Activity recognition permission denied',
        permissionsGranted: false,
      );
      return;
    }

    // 2. Configure Health plugin (required for Health Connect)
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

    // 3. Ensure Health Connect is available on Android
    if (await _ensureHealthConnect()) {
      // 4. Request Health permissions (read steps)
      final healthGranted = await _requestHealthPermissions();
      if (!healthGranted) {
        state = state.copyWith(
          isLoading: false,
          error: 'Health permissions denied',
          permissionsGranted: false,
        );
        return;
      }
    } else {
      state = state.copyWith(
        isLoading: false,
        error: 'Health Connect not available',
        permissionsGranted: false,
      );
      return;
    }

    // Permissions granted
    state = state.copyWith(permissionsGranted: true);

    // 6. Start pedometer listener
    _startPedometer();

    // 7. Set up observer for background changes
    _setupHealthObserver();

    state = state.copyWith(isLoading: false);
  }

  // --- Activity recognition permission ---
  Future<bool> _requestActivityPermission() async {
    final status = await Permission.activityRecognition.request();
    return status.isGranted;
  }

  // --- Ensure Health Connect is installed and SDK available (Android only) ---
  Future<bool> _ensureHealthConnect() async {
    // This check is only meaningful on Android
    // On iOS, HealthKit is always available if the device supports it.

    var status = await _health.getHealthConnectSdkStatus();
    developer.log('Health Connect SDK Status: $status');

    if (status != HealthConnectSdkStatus.sdkAvailable) {
      developer.log('Attempting to install/open Health Connect...');
      await _health.installHealthConnect();
      // Re-check after installation attempt
      status = await _health.getHealthConnectSdkStatus();
      developer.log('Health Connect SDK Status after install: $status');
    }

    return status == HealthConnectSdkStatus.sdkAvailable;
  }

  // --- Request Health permissions (read steps) ---
  Future<bool> _requestHealthPermissions() async {
    try {
      final types = [HealthDataType.STEPS];
      // Request read access only (you can add write if needed)
      final permissions = [HealthDataAccess.READ];

      // Check if already granted
      bool? hasPermissions = await _health.hasPermissions(
        types,
        permissions: permissions,
      );
      if (hasPermissions == true) {
        return true;
      }

      // Request authorization
      bool authorized = await _health.requestAuthorization(
        types,
        permissions: permissions,
      );
      developer.log('Health permission result: $authorized');
      return authorized;
    } catch (e) {
      developer.log('Health permission error: $e');
      state = state.copyWith(error: 'Health permission error: $e');
      return false;
    }
  }

  // --- Load dashboard data (Profile, Steps, Badges) from Supabase ---
  Future<void> loadWeeklySteps() async {
    print('loadWeeklySteps');

    try {
      await Future.microtask(() {});
      state = state.copyWith(isLoading: true);

      // 1. Fetch unified dashboard data from Edge Function
      final dashboardData = await _supabaseService.getStepsDashboardData();
      developer.log('Fetched dashboard data from Supabase');

      final profile = dashboardData['profile'] as Map<String, dynamic>;
      final today = dashboardData['today'] as Map<String, dynamic>;
      final weeklyRaw = dashboardData['weekly_steps'] as List;

      // 2. Parse weekly steps chart data
      final Map<DateTime, int> weeklySteps = {};
      for (var row in weeklyRaw) {
        final date = DateTime.parse(row['date'] as String);
        final normalizedDate = DateTime(date.year, date.month, date.day);
        weeklySteps[normalizedDate] = row['steps'] as int;
      }

      // 3. Update state with backend-authoritative values
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
        isLoading: false,
      );

      _lastSyncedSteps = state.steps;
      _stepsSinceLastSync = 0;
    } catch (e) {
      developer.log('Failed to load dashboard data: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load dashboard data: $e',
      );
    }
  }

  int _calculateStreak(Map<DateTime, int> data, int goal) {
    int streak = 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Check backwards from today (but exclude today if goal not yet met?)
    // Actually, usually streak includes today if met, or continues if today is still in progress
    // Let's check from yesterday backwards
    for (int i = 0; i < 30; i++) {
      final date = today.subtract(Duration(days: i));
      // For today, we might still be working on it, so don't break streak yet if not reached
      if (i == 0) {
        if ((data[date] ?? 0) >= goal) {
          streak++;
        }
        continue;
      }

      if ((data[date] ?? 0) >= goal) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  // --- Sync to Supabase ---
  Future<void> _syncToSupabase({bool force = false}) async {
    if (!force && state.steps == _lastSyncedSteps) return;

    try {
      await _supabaseService.upsertSteps(state.steps);
      await _badgeService.checkStepAchievements(state.steps);
      _lastSyncedSteps = state.steps;
      _stepsSinceLastSync = 0;
      developer.log('Synced steps to Supabase: ${state.steps}');
    } catch (e) {
      developer.log('Failed to sync steps to Supabase: $e');
    }
  }

  // --- Pedometer stream ---
  void _startPedometer() {
    try {
      _pedometerSubscription = Pedometer.stepCountStream.listen(
        (StepCount event) {
          _onPedometerUpdate(event.steps);
        },
        onError: (error) {
          developer.log('Pedometer error: $error');
          state = state.copyWith(error: 'Pedometer error: $error');
        },
      );
    } catch (e) {
      developer.log('Failed to start pedometer: $e');
      state = state.copyWith(error: 'Failed to start pedometer: $e');
    }
  }

  void _onPedometerUpdate(int newTotal) {
    if (_pedometerBaseline == null) {
      // First event: save as baseline
      _pedometerBaseline = newTotal;
      developer.log('Pedometer baseline set: $newTotal');
      return;
    }

    if (newTotal > _pedometerBaseline!) {
      int delta = newTotal - _pedometerBaseline!;
      _pedometerBaseline = newTotal;

      state = state.copyWith(steps: state.steps + delta);
      _stepsSinceLastSync += delta;

      // Sync only if taken 10 or more steps since last sync
      if (_stepsSinceLastSync >= 10) {
        _syncToSupabase();
      }
    }
  }

  // --- Health observer for background updates ---
  void _setupHealthObserver() {
    try {
      // Add observer for step changes
      // _healthObserverSubscription = _health.addObserver(HealthDataType.STEPS).listen((_) {
      //   developer.log('Health observer triggered: steps changed');
      //   _loadStepsFromPlatform(); // reload from platform
      // }, onError: (error) {
      //   developer.log('Health observer error: $error');
      // });
    } catch (e) {
      developer.log('Failed to set up health observer: $e');
      state = state.copyWith(error: 'Observer setup failed: $e');
    }
  }

  // --- Optional: write accumulated steps back to platform (if needed) ---
  // ...

  @override
  void dispose() {
    _pedometerSubscription?.cancel();
    _healthObserverSubscription?.cancel();
    _syncTimer?.cancel();
    super.dispose();
  }
}
