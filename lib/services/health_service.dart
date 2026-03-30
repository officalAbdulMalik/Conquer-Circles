import 'dart:async';
import 'dart:developer' as developer;

// Removed unused import: package:flutter_riverpod/flutter_riverpod.dart
import 'package:health/health.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:riverpod/legacy.dart';
 import 'package:test_steps/services/supabase_service.dart';
import 'package:test_steps/services/badge_service.dart';
import 'package:test_steps/services/notification_service.dart';
import 'package:test_steps/models/steps_model.dart';
// Removed unused import: dart:io

final stepProvider = StateNotifierProvider<StepNotifier, StepState>((ref) {
  return StepNotifier(SupabaseService(), BadgeService());
});

class StepNotifier extends StateNotifier<StepState> {
  final SupabaseService _supabaseService;
  final BadgeService _badgeService;

  StepNotifier(this._supabaseService, this._badgeService) : super(StepState.initial()) {
    initialize();
  }

  final Health _health = Health();
  StreamSubscription<StepCount>? _pedometerSubscription;
  StreamSubscription? _healthObserverSubscription;
  Timer? _syncTimer;

  int _lastSyncedSteps = -1;
  int _stepsSinceLastSync = 0;
  int? _pedometerBaseline;

  Future<void> initialize() async {
    state = state.copyWith(isLoading: true, error: null);

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

    // 5. Load steps for the last 7 days (Source of Truth)
    await _loadWeeklySteps();

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

  // --- Load steps for the last 7 days ---
  Future<void> _loadWeeklySteps() async {
    try {
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);
      final sevenDaysAgo = midnight.subtract(const Duration(days: 6));
      final types = [HealthDataType.STEPS];

      // 1. Fetch from Supabase
      final supabaseData = await _supabaseService.getWeeklyStepsFromSupabase();
      developer.log('Fetched ${supabaseData.length} records from Supabase');

      // 2. Fetch from Health Store
      final healthData = await _health.getHealthDataFromTypes(
        types: types,
        startTime: sevenDaysAgo,
        endTime: now,
      );

      final Map<DateTime, int> mergedWeeklyData = {};
      // Initialize with zeros for the last 7 days
      for (int i = 0; i < 7; i++) {
        final date = midnight.subtract(Duration(days: i));
        mergedWeeklyData[DateTime(date.year, date.month, date.day)] = 0;
      }

      // 3. Process Supabase data
      supabaseData.forEach((date, steps) {
        if (mergedWeeklyData.containsKey(date)) {
          mergedWeeklyData[date] = steps;
        }
      });

      // 4. Merge with Health data (take the maximum value for each day)
      for (var point in healthData) {
        if (point.value is NumericHealthValue) {
          final date = DateTime(
            point.dateFrom.year,
            point.dateFrom.month,
            point.dateFrom.day,
          );
          if (mergedWeeklyData.containsKey(date)) {
            // Some health providers return hourly data, so we sum them for the day
          }
        }
      }

      // Re-implementing the summation logic for health data
      final Map<DateTime, int> localHealthSum = {};
      for (var point in healthData) {
        if (point.value is NumericHealthValue) {
          final date = DateTime(
            point.dateFrom.year,
            point.dateFrom.month,
            point.dateFrom.day,
          );
          localHealthSum[date] =
              (localHealthSum[date] ?? 0) +
              (point.value as NumericHealthValue).numericValue.toInt();
        }
      }

      // Now merge: take the max of Supabase vs Local Health
      localHealthSum.forEach((date, steps) {
        if (mergedWeeklyData.containsKey(date)) {
          if (steps > (mergedWeeklyData[date] ?? 0)) {
            mergedWeeklyData[date] = steps;
          }
        }
      });

      int todaySteps = mergedWeeklyData[midnight] ?? 0;

      // Calculate streaks
      final weeklyStreak = _calculateStreak(mergedWeeklyData, 5000);

       state = state.copyWith(
        steps: todaySteps,
        weeklySteps: mergedWeeklyData,
        weeklyStreak: weeklyStreak,
        monthlyStreak: weeklyStreak > 0 ? weeklyStreak : 0,
      );

      // Check for streak reminder
      await NotificationService.checkStreakReminder(
        currentStreak: weeklyStreak,
        todaySteps: todaySteps,
        goalSteps: 5000,
      );

      _lastSyncedSteps = todaySteps;
      _stepsSinceLastSync = 0;

      // Ensure Supabase has this baseline value (it will upsert the best value we found)
      await _syncToSupabase(force: true);
    } catch (e) {
      developer.log('Failed to load weekly steps: $e');
      state = state.copyWith(error: 'Failed to load weekly steps: $e');
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
