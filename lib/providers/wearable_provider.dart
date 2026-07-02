import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_steps/services/supabase_service.dart';
import 'package:test_steps/services/wearable_service.dart';

enum WearableSyncStage {
  idle,
  requestingAccess,
  readingSteps,
  updatingDashboard,
  connected,
  failed,
}

class WearableState {
  const WearableState({
    this.isConnecting = false,
    this.isConnected = false,
    this.progress = 0,
    this.syncedSteps = 0,
    this.stage = WearableSyncStage.idle,
    this.error,
    this.syncedAt,
    this.healthSource,
  });

  final bool isConnecting;
  final bool isConnected;
  final double progress;
  final int syncedSteps;
  final WearableSyncStage stage;
  final String? error;
  final DateTime? syncedAt;
  final String? healthSource;

  WearableState copyWith({
    bool? isConnecting,
    bool? isConnected,
    double? progress,
    int? syncedSteps,
    WearableSyncStage? stage,
    String? error,
    bool clearError = false,
    DateTime? syncedAt,
    String? healthSource,
  }) {
    return WearableState(
      isConnecting: isConnecting ?? this.isConnecting,
      isConnected: isConnected ?? this.isConnected,
      progress: progress ?? this.progress,
      syncedSteps: syncedSteps ?? this.syncedSteps,
      stage: stage ?? this.stage,
      error: clearError ? null : error ?? this.error,
      syncedAt: syncedAt ?? this.syncedAt,
      healthSource: healthSource ?? this.healthSource,
    );
  }
}

class WearableNotifier extends StateNotifier<WearableState> {
  WearableNotifier(this._service) : super(const WearableState()) {
    _hydrateFromStorage();
  }

  final WearableService _service;
  Timer? _progressTimer;

  static const _kConnected = 'watch_connected';
  static const _kSyncedSteps = 'watch_synced_steps';
  static const _kSyncedAt = 'watch_synced_at';

  /// Restores the "watch connected" state from a previous session so the home
  /// screen can immediately show synced steps instead of the connect prompt.
  Future<void> _hydrateFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!(prefs.getBool(_kConnected) ?? false)) return;
      if (state.isConnecting) return;
      final atMs = prefs.getInt(_kSyncedAt);
      state = state.copyWith(
        isConnected: true,
        stage: WearableSyncStage.connected,
        progress: 1,
        syncedSteps: prefs.getInt(_kSyncedSteps) ?? 0,
        syncedAt: atMs != null
            ? DateTime.fromMillisecondsSinceEpoch(atMs)
            : null,
      );
    } catch (_) {
      // Storage unavailable — leave state as disconnected.
    }
  }

  Future<void> _persistConnection(int steps, DateTime at) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kConnected, true);
      await prefs.setInt(_kSyncedSteps, steps);
      await prefs.setInt(_kSyncedAt, at.millisecondsSinceEpoch);
    } catch (_) {
      // Non-fatal: the sync still succeeded this session.
    }
  }

  /// Connect the watch by granting Health access and syncing today's steps.
  /// On iOS this reads Apple Watch steps via Apple Health; on Android via
  /// Health Connect. No Bluetooth pairing is involved.
  Future<void> connectAndSync({required int currentSteps}) async {
    if (state.isConnecting) return;

    _startProgress();
    state = WearableState(
      isConnecting: true,
      progress: 0.12,
      syncedSteps: currentSteps,
      stage: WearableSyncStage.requestingAccess,
    );

    try {
      final granted = await _service.requestHealthAccess();
      if (!granted) {
        throw Exception(
          defaultTargetPlatform == TargetPlatform.iOS
              ? 'Allow Apple Health access so we can read your Apple Watch steps.'
              : 'Allow Health Connect access so we can read your watch steps.',
        );
      }

      state = state.copyWith(
        stage: WearableSyncStage.readingSteps,
        progress: 0.5,
      );
      final healthResult = await _service.fetchSteps(
        fallbackSteps: currentSteps,
      );

      state = state.copyWith(
        stage: WearableSyncStage.updatingDashboard,
        syncedSteps: healthResult.steps,
        progress: 0.85,
      );
      await _service.pushStepsToSupabase(healthResult.steps);

      _stopProgress();
      final syncedAt = DateTime.now();
      await _persistConnection(healthResult.steps, syncedAt);
      state = state.copyWith(
        isConnecting: false,
        isConnected: true,
        progress: 1,
        syncedSteps: healthResult.steps,
        stage: WearableSyncStage.connected,
        syncedAt: syncedAt,
        healthSource: healthResult.source,
        clearError: true,
      );
    } catch (e) {
      _stopProgress();
      state = state.copyWith(
        isConnecting: false,
        isConnected: false,
        progress: 0,
        stage: WearableSyncStage.failed,
        error: _friendlyError(e),
      );
    }
  }

  String _friendlyError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  void _startProgress() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 380), (_) {
      if (!state.isConnecting) return;
      final nextProgress = (state.progress + 0.05).clamp(0.12, 0.92);
      state = state.copyWith(progress: nextProgress);
    });
  }

  void _stopProgress() {
    _progressTimer?.cancel();
    _progressTimer = null;
  }

  @override
  void dispose() {
    _stopProgress();
    super.dispose();
  }
}

final wearableProvider = StateNotifierProvider<WearableNotifier, WearableState>(
  (ref) {
    return WearableNotifier(WearableService(SupabaseService()));
  },
);
