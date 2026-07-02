import 'dart:async';

import 'package:riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test_steps/features/leaderboard/models/leaderboard_participant.dart';
import 'package:test_steps/services/supabase_service.dart';

class LeaderboardState {
  const LeaderboardState({
    this.selectedMetric = LeaderboardMetric.territoryTiles,
    this.data,
    this.isLoading = false,
    this.isRefreshing = false,
    this.error,
  });

  final LeaderboardMetric selectedMetric;
  final LeaderboardData? data;
  final bool isLoading;
  final bool isRefreshing;
  final String? error;

  List<LeaderboardParticipant> get participants {
    return data?.participants ?? const [];
  }

  LeaderboardState copyWith({
    LeaderboardMetric? selectedMetric,
    LeaderboardData? data,
    bool? isLoading,
    bool? isRefreshing,
    String? error,
  }) {
    return LeaderboardState(
      selectedMetric: selectedMetric ?? this.selectedMetric,
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: error,
    );
  }
}

class LeaderboardNotifier extends StateNotifier<LeaderboardState> {
  LeaderboardNotifier(this._service) : super(const LeaderboardState()) {
    load();
    _subscribeToRealtime();
  }

  final SupabaseService _service;
  RealtimeChannel? _channel;
  Timer? _refreshDebounce;

  Future<void> load({bool showLoader = true}) async {
    state = state.copyWith(
      isLoading: showLoader && state.data == null,
      isRefreshing: !showLoader,
      error: null,
    );

    try {
      final data = await _service.getSeasonLeaderboard(
        metric: state.selectedMetric,
      );
      state = state.copyWith(
        data: data,
        isLoading: false,
        isRefreshing: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refresh() => load(showLoader: false);

  void selectMetric(LeaderboardMetric metric) {
    if (metric == state.selectedMetric) return;
    state = state.copyWith(selectedMetric: metric);
    unawaited(load(showLoader: false));
  }

  void _subscribeToRealtime() {
    _channel = Supabase.instance.client
        .channel('leaderboard_realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'daily_steps',
          callback: (_) => _scheduleRefresh(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'territories',
          callback: (_) => _scheduleRefresh(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'territory_attack_log',
          callback: (_) => _scheduleRefresh(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'profiles',
          callback: (_) => _scheduleRefresh(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'seasons',
          callback: (_) => _scheduleRefresh(),
        )
        .subscribe();
  }

  void _scheduleRefresh() {
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(
      const Duration(milliseconds: 700),
      () => unawaited(load(showLoader: false)),
    );
  }

  @override
  void dispose() {
    _refreshDebounce?.cancel();
    final channel = _channel;
    if (channel != null) {
      unawaited(Supabase.instance.client.removeChannel(channel));
    }
    super.dispose();
  }
}

final leaderboardProvider =
    StateNotifierProvider<LeaderboardNotifier, LeaderboardState>((ref) {
      return LeaderboardNotifier(SupabaseService());
    });
